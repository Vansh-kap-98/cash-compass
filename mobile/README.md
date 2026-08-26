# Cash Compass — Flutter (Android)

The live app. A personal finance dashboard that runs entirely on-device.

New to this repo? Read the [root README](../README.md) first for how the two
directories relate, then come back here.

## Start here

| I want to… | Go to |
| --- | --- |
| Install the toolchain and run the app | [SETUP.md](SETUP.md) |
| Know what's built and what isn't | [../CURRENT_FEATURES.md](../CURRENT_FEATURES.md) |
| Implement a feature to match the web app | [PARITY_SPEC.md](PARITY_SPEC.md) |
| Build and hand out an APK | [SETUP.md §6](SETUP.md) |

## Quick run

Assuming the Flutter toolchain is already installed and a device is connected:

```bash
flutter pub get
```

```bash
flutter run
```

No credentials are needed. Supabase is not configured, so the app opens
straight into offline demo mode.

## Checks before you push

```bash
flutter analyze
```

```bash
flutter test
```

```bash
dart format lib test
```

All three should be clean. The formatter is not optional — [.editorconfig](../.editorconfig)
pins Dart to `dart format` output, so an unformatted file shows up as noise in
someone else's diff.

## Layout

```
lib/
├── app/          Theme tokens, ThemeData, scroll behaviour
├── dev/          Debug-only helpers — sample data, frame timing, logging
├── logic/        Pure Dart. No Flutter imports, unit-tested directly
├── models/       Data classes and JSON helpers
├── screens/      One file per screen, tabs under screens/tabs/
├── services/     Storage, HTTP, Supabase, secure session
├── state/        ChangeNotifier providers — the React Context equivalents
└── widgets/      Reusable UI, workspace cards under widgets/workspace/
```

Two conventions worth knowing before you write code here:

**Business rules live in `lib/logic/`, not in widgets.** Those files import no
Flutter, so every rule is testable without an emulator. When you add a
calculation, put it there and test it directly.

**All money is stored in USD.** Conversion happens at the edges — on input and
on display. `PARITY_SPEC.md` §0 explains why, and documents the two places the
React app got this wrong that this port deliberately does not reproduce.

## Debug vs release

`SampleData` and everything in [lib/dev/log.dart](lib/dev/log.dart) are
`kDebugMode`-guarded and compiled out of release builds. That is deliberate:
`debugPrint` is **not** stripped from release by Flutter, and anything it prints
is readable through `adb logcat`. Never log an amount, token, or email outside
that helper.
