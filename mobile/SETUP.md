# Cash Compass — Flutter (Android) setup

This folder holds the Flutter port of the React app in `../frontend`. The React
app stays as the reference spec; nothing is shared between the two builds.

The app is complete and building. What this guide covers is getting the
Flutter toolchain onto a new machine so you can run it — the Android
scaffolding (`android/`, `.metadata`) is already committed, so there is no
project generation step.

## 1. Install the toolchain

If `flutter --version` already works, skip to section 2. Otherwise do these
in order.

### Flutter SDK

Download the Windows stable ZIP from <https://docs.flutter.dev/install/archive>
and extract it to `C:\src\flutter`.

Path rules that matter — getting these wrong causes build failures that are hard
to diagnose:

- No spaces in the path.
- Not under `C:\Program Files` (needs elevation, breaks the tool).
- Not inside a OneDrive-synced folder — file syncing corrupts builds.
- Not on a network drive.

Add it to your user PATH. Run this in PowerShell — it appends to the *user*
PATH only, leaving the system PATH untouched:

```bash
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";C:\src\flutter\bin", "User")
```

Do **not** use `setx PATH "%PATH%;..."` — it merges the system PATH into your
user PATH and silently truncates at 1024 characters.

Open a **new** terminal, then confirm:

```bash
flutter --version
```

### Android Studio

```bash
winget install --id Google.AndroidStudio -e
```

Launch it once and complete the Setup Wizard (choose *Standard*). Then open
**Settings → Languages & Frameworks → Android SDK → SDK Tools** and make sure
**Android SDK Command-line Tools (latest)** is ticked — `flutter doctor` fails
without it.

You can edit day to day in VS Code with the Dart and Flutter extensions; Android
Studio is only needed for the SDK and emulator.

### Clear the doctor

```bash
flutter doctor -v
```

Green is required for *Flutter*, *Android toolchain*, and *Android Studio*.
Chrome and Visual Studio can stay red — this project is Android-only.

Accept the licences (answer `y` to each prompt):

```bash
flutter doctor --android-licenses
```

## 2. Get a device

**A physical phone is strongly preferred** — faster, and it avoids the
virtualisation setup entirely.

1. Settings → About phone → tap **Build number** seven times.
2. Settings → Developer options → enable **USB debugging**.
3. Connect with a **data-capable** USB cable. Charge-only cables fail silently
   and are the single most common time sink here.
4. Set the USB mode to **File Transfer**, not "Charging only".
5. Accept the RSA fingerprint prompt on the phone.

```bash
flutter devices
```

If you use an emulator instead, it needs hardware acceleration: enable
virtualisation (VT-x on Intel, SVM on AMD) in BIOS, then enable the Windows
Hypervisor Platform feature. Without it the emulator is unusably slow.

## 3. Android scaffolding — already committed

`android/` and `.metadata` are in the repository, so a fresh clone needs
nothing here. Skip to section 4.

Only if the `android/` directory is somehow missing or corrupted, this
regenerates it without touching `lib/` or `pubspec.yaml`:

```bash
flutter create --org com.cashcompass --platforms=android --project-name cash_compass .
```

Then:

```bash
flutter pub get
```

> If `flutter create` overwrites `pubspec.yaml`, restore it from git — the
> version in this repo already lists every dependency the port needs.

## 3b. Known toolchain gotchas

Two issues you will hit on a fresh machine, both caused by Google replacing
`sdkmanager` with a new `android` CLI.

**`flutter doctor` says "Android license status unknown".** Usually a false
alarm. Doctor probes the old `sdkmanager`, gets deprecation warnings instead of
a parseable answer, and reports "unknown" — not "missing". Check the real state:

```bash
type "%LOCALAPPDATA%\Android\sdk\licenses\android-sdk-license"
```

If that file exists with a hash in it, licences are accepted and you can ignore
the warning. Android Studio's Setup Wizard accepts them for you.

**Build fails with `Package ndk not found. Package 28.2.13676358 not found.`**
The `jni` plugin (pulled in by `supabase_flutter`) needs the NDK. Gradle tries
to auto-install it using the old `ndk;<version>` semicolon syntax, which the new
CLI parses as *two* package names — hence the doubled error. Install it yourself
with the new slash syntax (~713 MB):

```bash
android sdk install "ndk/28.2.13676358"
```

The `android` binary lives in `%LOCALAPPDATA%\Android\sdk\cmdline-tools\latest\bin`.
Once installed, Gradle finds it and skips its broken auto-install path.

## 4. Supabase configuration

The app is built to boot without Supabase keys, falling straight into demo mode,
so you can skip this until milestone M4.

Create `config/dev.json` (git-ignored):

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

Run with:

```bash
flutter run --dart-define-from-file=config/dev.json
```

Values are read via `String.fromEnvironment`, so nothing is bundled as a
readable asset. The anon key is public by design; this is about hygiene, not
secrecy.

**Suggestion for v1:** turn off "Confirm email" in the Supabase dashboard. Email
confirmation requires Android deep-link setup (a custom scheme plus an
`intent-filter`), and since no finance data is stored server-side it buys very
little. Add it later if real accounts start to matter.

## 5. Run it

```bash
flutter run
```

In the running terminal: `r` hot-reloads (state preserved), `R` hot-restarts
(state wiped), `q` quits. Hot reload is the Vite HMR equivalent; changes to
`main()` or to enum shapes need a full restart.

## 6. Build an installable APK

A plain `flutter build apk --release` produces a debug-key-signed, unobfuscated
APK. That is fine for a throwaway smoke test on your own emulator. For anything
you carry around on a phone with real financial data, do the signed build below.

### One-time: create a keystore

Never reuse a keystore from another project, and never keep using the Android
debug key for a build that persists.

`keytool` ships with the JDK bundled inside Android Studio and is usually not on
PATH:

```bash
"C:\Program Files\Android\Android Studio\jbrin\keytool.exe" -genkey -v -keystore "$HOME/keystores/cash-compass-test.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias cashcompass
```

Copy `android/key.properties.example` to `android/key.properties` and fill in
the passwords you just chose. Both `key.properties` and `*.jks` are gitignored;
keep the `.jks` file backed up somewhere outside the repo, because losing it
means you can never ship an update that upgrades an already-installed copy.

If `key.properties` is absent the release build still works — it falls back to
the debug key and prints a warning. Don't distribute that APK.

### Build

```bash
flutter build apk --release --obfuscate --split-debug-info=build/debug-info --dart-define-from-file=config/dev.json
```

Output lands at `build/app/outputs/flutter-apk/app-release.apk`.

`--obfuscate` renames Dart symbols in `libapp.so`; `--split-debug-info` writes
the map needed to turn an obfuscated crash trace back into readable frames.
Keep `build/debug-info` for any build you actually install — without the map
from that exact build, its stack traces are unreadable. It is gitignored.

### Install

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

Or copy the APK to the phone and open it — that needs "install from unknown
sources" granted to whichever app opens it, a one-time device setting.

### What the release build hardens

| Measure | Where |
| --- | --- |
| Session tokens in the Android Keystore, not plaintext prefs | `lib/services/secure_session_store.dart` |
| All logging compiled out of release | `lib/dev/log.dart` |
| Cleartext HTTP blocked OS-wide | `android/app/src/main/res/xml/network_security_config.xml` |
| No `adb backup` extraction of app data | `android:allowBackup="false"` in the manifest |
| R8 shrinking + resource stripping | `android/app/build.gradle.kts`, keep rules in `proguard-rules.pro` |

Verify the signature before you trust a build:

```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

The fingerprint must match your keystore, not the Android debug key (whose CN is
`Android Debug`).

## What's already written

| Path | Purpose |
| --- | --- |
| `lib/app/theme/app_tokens.dart` | Soft Bloom design tokens, transcribed from `frontend/src/index.css` |
| `lib/app/theme/app_theme.dart` | Builds `ThemeData` from a token set |
| `lib/models/` | `FinanceTransaction`, `SavingsGoal`, `BudgetCategory`, JSON helpers |
| `lib/services/prefs.dart` | Storage wrapper; all 13 keys in one place |
| `lib/services/rates_api.dart` | frankfurter.app client |
| `lib/state/finance_provider.dart` | Port of `FinanceContext.tsx` |
| `lib/state/currency_provider.dart` | Port of `CurrencyContext.tsx` |
| `lib/state/theme_provider.dart` | Port of `ThemeContext.tsx` + font settings |

That table is a partial snapshot from early in the port. Everything listed
there shipped, along with `main.dart`, the router, auth, and every screen. For
the current state of each feature see
[../CURRENT_FEATURES.md](../CURRENT_FEATURES.md), which is kept up to date.
