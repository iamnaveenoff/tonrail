# Contributing

Thanks for helping. This project is small and friendly; a short, clear issue or a focused pull request is the best way in.

## Ways to help

- **Device reports.** Tell us if the app works (or doesn't) with your headphones, especially a different firmware. Use the *Device report* issue template and attach the Diagnostics log (Device → Diagnostics → copy).
- **Bug reports.** Steps to reproduce, what you expected, what happened, phone model and Android version.
- **Translations.** Not wired up yet; open an issue first so we can add localization together.
- **Code.** Fixes and features. For anything bigger than a small fix, open an issue first so we agree on the approach.

## Development setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) 3.44+ (Dart 3.12), the Android SDK and JDK 17.
2. `flutter pub get`
3. `flutter run` with a phone connected over USB. Bluetooth does not work in the Android emulator, so real hardware is needed to test the connection; the UI and protocol tests run without it.

## Before you open a pull request

```bash
dart format lib test        # page width 120 is set in analysis_options.yaml
flutter analyze             # must report no issues
flutter test                # must pass
```

If you changed how a screen looks, regenerate the README screenshots and include them:

```bash
flutter test test/screenshots_test.dart --dart-define=SCREENSHOTS=true
```

## Code guide

- `lib/protocol/` is pure Dart with no Flutter or Bluetooth imports. Keep it that way so it stays easy to test. Add a test in `test/protocol_test.dart` for any new command or parser.
- `lib/device/headset_controller.dart` owns the Bluetooth link and device state. Settings are applied optimistically and reverted if the headphones reject them.
- `lib/ui/` follows the visual system in [DESIGN.md](DESIGN.md): orange marks only the active state, one typeface (Archivo), legends in small caps. Reuse the widgets in `lib/ui/widgets/panel.dart` before writing new ones.
- Every touch target is at least 48 dp, custom-painted controls carry `Semantics` labels, and animations respect the system "Remove animations" setting.
- Copy is plain and short. Controls say what they do; errors say what went wrong and how to fix it.

## Protocol changes

The Bluetooth commands were worked out by observation. If you change or add one, describe in the pull request how you verified it on real headphones, and update [docs/PROTOCOL.md](docs/PROTOCOL.md). Never add commands that could brick the device (firmware updates, raw writes) without discussion.

## Commits

Small commits with clear messages, for example `eq: snap balance to centre`. Pull requests are squashed when merged.

## Licensing

By contributing you agree that your contribution is licensed under the [MIT License](LICENSE).
