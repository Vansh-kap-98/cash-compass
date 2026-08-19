# Cash Compass — Flutter (Android) setup

This folder holds the Flutter port of the React app in `../frontend`. The React
app stays as the reference spec; nothing is shared between the two builds.

The Dart source in `lib/` is written and ready. What's missing is the Flutter
SDK and the Android scaffolding (`android/`, `.metadata`, etc.), which only
`flutter create` can generate.

## 1. Install the toolchain

Nothing Flutter-related is installed on this machine yet. Do these in order.

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

## 3. Generate the Android scaffolding

Run this **from inside this folder**. It fills in the missing platform files
without touching the existing `lib/` or `pubspec.yaml`:

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

```bash
flutter build apk --release
```

Output lands at `build/app/outputs/flutter-apk/app-release.apk`.

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

Still to come: `main.dart`, the router, auth, and the screens. `main.dart` is
deliberately not written yet because `flutter create` generates its own and
would overwrite it.
