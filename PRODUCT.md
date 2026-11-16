# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users
Owners of the supported over-ear headphones (see README ? Compatibility), starting with the developer, who want a cleaner, better alternative to the official companion app for day-to-day listening control. They open the app briefly and often: switch noise control on a commute, change the sound for a genre or task, and then put the phone away.

## Product Purpose
Tonrail controls the headphones over Bluetooth LE. It switches noise control, tunes sound, remaps buttons, and manages device settings. Success means common changes take one tap, tuning feels direct and safe, and the app always says plainly whether it is connected.

## Positioning
An independent controller that reads its state back from the headphones and makes changes immediately. It adds features the official app lacks: Moments (one-tap noise + sound + latency combinations), saved custom EQ presets, hold-to-compare against flat, and headroom protection so boosted EQ never distorts.

## Operating Context
- Used one-handed, often on the move or in noisy places, in short sessions.
- Only one app can hold the headphones' control link at a time; the official companion app must be closed.
- Settings live on the headphones; presets and Moments live on the phone (SharedPreferences).

## Capabilities and Constraints
- Noise control: Off; Noise cancel scenes (Adaptive, Loud places, Commute, Indoor, Wind; three of them have 3 strength levels); Aware (transparency).
- Sound: 6 factory tunings (Signature, Pop, Bass, Rock, Soft, Classical; 7-band, read-only); a 10-band custom curve (60 Hz–16 kHz, −8 to +8 dB in 0.5 dB steps); user presets (save, rename, delete); hold to compare against flat; L/R balance.
- Gaming mode (low latency).
- Buttons: Multifunction ×1–×4, Volume +, Volume − map to 8 functions; restore defaults.
- Device: rename, auto power-off timer, restore noise mode on reconnect, headroom protection, connect/disconnect, diagnostics log, restore factory settings, forget all paired phones.
- Battery level and charging state are reported.
- Not offered: firmware updates.

## Brand Commitments
- Name: "Tonrail" (repository `tonrail`), open source under MIT.
- No headphone-maker names, logos or trade dress in the app or branding. The supported model is named only in the README's compatibility section, with a non-affiliation disclaimer. The app states it is independent and not affiliated with any headphone maker.
- Dark theme is the default; light theme is supported.

## Evidence on Hand
No testimonials, reviews, or product photography. The connected panel shows a drawn, generic over-ear headphone illustration (requested by the owner); it must not copy any real product's design or show invented claims.

## Product Principles
1. Connection state is always visible and honest.
2. The most frequent action (noise control) is one tap from launch.
3. Tuning is direct, reversible, and safe for hearing and hardware.
4. Every control explains itself in plain words; nothing technical is shown unless asked.
5. Fast to open, fast to put away.

## Accessibility & Inclusion
Touch targets of at least 48 dp, honors system text scaling and reduce-motion, and every custom-painted control has semantics labels.
