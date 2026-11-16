# Bluetooth protocol notes

These notes describe how Tonrail talks to the supported headphones (see the README's Compatibility section). They were worked out independently for interoperability, not from any official documentation, so treat them as best current knowledge. The source of truth is the code in [`lib/protocol/`](../lib/protocol/) and its tests.

## Discovery

The headphones expose two Bluetooth identities:

| Name | Transport | Use |
|---|---|---|
| `<model>` | Classic Bluetooth | Audio. Paired in Android settings. |
| `<model>-APP` | Bluetooth LE | Control link used by this app. |

The control link advertises manufacturer data with company ID `0x522C`. Bytes 11–16 of that data carry the classic audio MAC, which the app uses to prefer the headphones paired with this phone.

GATT layout:

| Service | Characteristic | Direction |
|---|---|---|
| `A002` | `0001` | Write (phone → headphones) |
| `A002` | `0002` | Notify (headphones → phone) |

The app requests an MTU of 247 and splits writes to `MTU − 3` bytes.

## Framing

```text
FE DC BA | flags | opcode | length (u16, big-endian) | body | EF
```

- `flags` bit 7 = command (set) or response (clear); bit 6 = response wanted.
- Command body: `sn | payload`.
- Response body: `status | sn | payload`. `status 00` means success.
- `sn` is a sequence number the app increments per command; replies echo it.

Example, set noise control to Aware:

```text
→ FE DC BA C0 FF 00 06 0B 17 03 03 01 04 EF
← FE DC BA 00 FF 00 02 00 0B EF            (status 00, sn 0B)
```

## Opcodes

| Opcode | Name | Payload |
|---|---|---|
| `03` | Get target info | `FF FF FF FF 00` |
| `C0` | Set setting | `len type data…` (see setting types) |
| `C1` | Read settings | 32-bit mask, `FF FF FF FF` = all |
| `C2` | Status notify (from headphones) | battery and similar |
| `C4` | Settings changed (from headphones) | app re-reads settings |
| `C5` | System operation | `01` factory reset, `02` forget all pairings |
| `FF` | Custom command | `attr len data…` |

## Setting types (`C0` / `C1`)

| Type | Meaning | Data |
|---|---|---|
| `00` | Battery | per side: bit 7 = charging, bits 0–6 = percent |
| `01` | Name | UTF-8 |
| `02` | Button map | triplets `key action function` |
| `05` | Gaming mode | `01` off, `02` on |
| `07` | Time sync | Unix seconds, u32 big-endian |
| `0B` | Noise mode (raw) | |
| `0C` | Balance | `0`–`100`, `50` = centre |

Buttons: key `07` Multifunction (actions `01`–`04` = 1–4 presses), `05` Volume +, `03` Volume −. Functions: `01` play/pause, `02` previous, `03` next, `04` voice assistant, `05` volume up, `06` volume down, `07` gaming mode, `7F` do nothing.

## Custom commands (`FF`)

Query any attribute with `FE 01 attr`.

### Noise control, attribute `0x17` (23)

Set with `17 03 mode scene level`.

| Mode | Meaning | Scenes |
|---|---|---|
| `01` | Noise cancelling | `01` loud places, `02` commute, `03` indoor, `04` wind, `05` adaptive |
| `02` | Off | |
| `03` | Aware (transparency) | `01` |

`level` is `0`–`2` for loud places, commute and indoor.

### Auto power-off, attribute `0x14` (20)

`14 04 lo hi 00 00`: minutes as u16 little-endian; `FFFF` = never.

### Equalizer, attributes `0x22` (v2) and `0x20` (v1)

```text
attr  len  FF  master_lo master_hi  [band]…
band (v1): freq_lo freq_hi gain_lo gain_hi q_lo q_hi
band (v2): same, plus 1 byte filter type (02 = peaking)
```

- Gains and master are signed 16-bit, little-endian, in hundredths of a dB.
- Q is in hundredths.
- The app queries `0x22` first and falls back to `0x20` to detect the format.
- The custom curve uses 10 bands at 60, 220, 500, 1k, 2k, 2.5k, 5k, 7.5k, 12k and 16k Hz.
- Master gain is lowered so the summed curve never clips: to 0 dB peak with headroom protection on, or only above +8 dB with it off.
