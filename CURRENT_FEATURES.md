# Current features

Implementation status of the Flutter app in `mobile/`. The React app in
`frontend/` is the reference spec, not a delivery target, so it is not tracked
here — see [mobile/PARITY_SPEC.md](mobile/PARITY_SPEC.md) for what the port is
measured against.

**Keep this file current.** When a PR changes what works, update the row it
affects in the same PR. A status doc that lags the code is worse than none,
because people trust it.

| Status | Meaning |
| --- | --- |
| ✅ Done | Built, wired into the UI, and covered by tests where the logic is testable |
| 🟡 Partial | Works, but a named piece is missing — the "Remaining" column says which |
| ⚪ Not started | No code exists |

Last verified against `main` on 2026-08-24 (`flutter analyze` clean, 308 tests passing).

---

## Screens

| Feature | Status | Remaining |
| --- | --- | --- |
| Auth screen — sign in, sign up, demo mode | ✅ | — |
| Dashboard tab | ✅ | — |
| Goals tab | ✅ | — |
| Planner tab | ✅ | — |
| Workspace tab | ✅ | — |
| Settings tab | ✅ | — |
| Budget plan screen | ✅ | — |
| Android hardware back / routing (`go_router`) | ✅ | — |

The dashboard renders the full card stack: balance snapshot, stat grid, budget
range, smart cards, spending pattern, daily planner, location guidance,
suggestions, insight box, subscriptions, event calendar, recent transactions,
and day records.

> The class comment at [dashboard_tab.dart:12](mobile/lib/screens/tabs/dashboard_tab.dart:12)
> still says the planner, insights, and event calendar "land in later
> milestones". That is stale — all three ship. Worth fixing next time the file
> is touched.

## Core finance

| Feature | Status | Remaining |
| --- | --- | --- |
| Transactions — add, edit, delete, categorise | ✅ | — |
| Savings goals | ✅ | — |
| Budget categories and plans | ✅ | — |
| Day plans / daily planner | ✅ | — |
| Fixed liabilities | ✅ | — |
| Manual balance entry, derived stats | ✅ | — |
| Multi-currency with live FX (frankfurter.app) | ✅ | — |
| Persistence (`shared_preferences`, debounced writes) | ✅ | — |

All amounts normalise to USD on input and convert on display, per
`PARITY_SPEC.md` §0. The two conventions the web app got wrong are
deliberately **not** reproduced.

## Derived logic

Pure Dart, no Flutter imports, unit-tested independently of the UI.

| Module | Status | Remaining |
| --- | --- | --- |
| [budget_math.dart](mobile/lib/logic/budget_math.dart) | ✅ | — |
| [insights.dart](mobile/lib/logic/insights.dart) — behaviour rules, smart cards | ✅ | — |
| [events.dart](mobile/lib/logic/events.dart) — event calendar | ✅ | — |
| [subscriptions.dart](mobile/lib/logic/subscriptions.dart) — recurring-charge detection | ✅ | — |
| [student_planner.dart](mobile/lib/logic/student_planner.dart) | ✅ | — |
| [receipt_parser.dart](mobile/lib/logic/receipt_parser.dart) | 🟡 | Logic and tests are done; nothing calls it — see [Receipt scanning](#receipt-scanning) |

## Workspace widgets

All 15 types render, resize (S/M/L), reorder, and persist.

| Widget | Status | Notes |
| --- | --- | --- |
| Today Snapshot, Budget Health, Top Categories, Goal Progress | ✅ | |
| Safe-to-Spend, Sub-Stash Jar, Burn-Rate Line, Quick-Entry Pad | ✅ | |
| Waste Auditor | ✅ | Reads real detected subscriptions, not the web app's hardcoded values |
| Roommate Sync | ✅ | Reads real multi-person budget plans |
| Manga Status, ASCII Fortune, Chibi Mascot, Growth Gem | ✅ | |
| Image (`media`) | ✅ | Stored in app-private storage |

`PARITY_SPEC.md` §10 listed six dead controls in the original. All are resolved
— the chibi mascot click now cycles faces, and the waste-auditor `✕` and the
event calendar's cosmetic "Apply safety margin" toggle were removed rather than
faked.

---

## Partial

### Themes

**🟡 1 of 5 implemented.**

Only Soft Bloom is registered in
[appThemes](mobile/lib/app/theme/app_tokens.dart:116). The other four —
retro-pixel, modern-academic, kawaii-pastel, cyber-terminal — have their full
token values transcribed in `PARITY_SPEC.md` §9 but no `AppTokens` entry.

**To finish:** add each as an `AppTokens` entry in that map. No other code
changes are needed; theme resolution, persistence, and the legacy-alias
migration already handle arbitrary entries. Two of them also need non-token
work — retro-pixel uses a hard `4px 4px 0` shadow with no blur plus a
crosshatch background, and each theme specifies its own fonts.

### Receipt scanning

**🟡 Parser only.**

| Piece | Status |
| --- | --- |
| Amount / merchant / category extraction with confidence scoring | ✅ Done, unit-tested against fixture text |
| `google_mlkit_text_recognition` dependency | ✅ In `pubspec.yaml` (and shipping in the APK) |
| Camera capture | ⚪ Not started |
| ML Kit OCR call (`TextRecognizer`, `InputImage`) | ⚪ Not started |
| UI to review and confirm a parsed receipt | ⚪ Not started |
| Receipt image storage | ⚪ Not started |

Nothing in `lib/` constructs a `TextRecognizer` or opens the camera —
[image_store.dart](mobile/lib/services/image_store.dart:38) uses
`ImageSource.gallery` and serves the workspace image widget, not receipts.

**To finish:** capture an image, hand it to ML Kit, feed the recognised lines
into the existing `ParsedReceipt` pipeline, and build a confirm screen that
surfaces `FieldConfidence` so an OCR guess never looks as certain as typed
input. This will also need a `CAMERA` permission plus a runtime request with a
rationale — deliberately not declared yet, since shipping an unused dangerous
permission is worse than adding it when it is real.

### Supabase / accounts

**🟡 Code written, not configured.**

| Piece | Status |
| --- | --- |
| Client init, sign in / up / out, profile upsert | ✅ Written |
| Demo mode bypass, fully offline | ✅ Works |
| Session tokens in Android Keystore | ✅ [secure_session_store.dart](mobile/lib/services/secure_session_store.dart) |
| A configured Supabase project | ⚪ Deferred by decision |
| Any financial data server-side | ⚪ Not started |

There is no `config/dev.json`, so `isSupabaseConfigured` is false and the app
boots into demo mode. That is the intended state for now.

**Consequence to be aware of:** all financial data is device-local. There is no
sync, no multi-device, and no recovery — clearing app data loses everything.

### Release build

**🟡 Pipeline done, keystore not generated.**

| Piece | Status |
| --- | --- |
| `INTERNET` permission in the release manifest | ✅ |
| Network security config — cleartext denied | ✅ |
| `allowBackup="false"` | ✅ |
| All logging compiled out of release ([log.dart](mobile/lib/dev/log.dart)) | ✅ |
| Debug seeder excluded from release (verified by APK scan) | ✅ |
| R8 shrinking + ProGuard keep rules | ✅ |
| Dart obfuscation + split debug info | ✅ |
| Gradle signing config reading `key.properties` | ✅ |
| An actual release keystore | ⚪ Must be generated by the maintainer |

Builds today fall back to the local Android debug key, which is fine for your
own device but cannot be distributed — see
[Releasing an APK](README.md#releasing-an-apk).

---

## Not started

| Feature | Notes |
| --- | --- |
| **Social benchmarks** (`PARITY_SPEC.md` §7) | No code anywhere in `lib/`. Needs the city/course cost table, the private-lobby opt-in (`cash-compass-private-lobby-v1`), the seed challenge, and the leave-lobby control the web app claims but never implemented. |
| **Backend / data sync** | Undecided between the maintainer's Python/FastAPI + MySQL service and finishing Supabase. Until one lands, `mobile/` and `frontend/` hold entirely separate data for the same account. |
| **Themes 2–5** | See [Themes](#themes) above. |
| **Receipt capture + OCR** | See [Receipt scanning](#receipt-scanning) above. |
| **iOS** | Android only; `pubspec.yaml` and the setup guide assume it. No `ios/` directory exists. |
| **CI** | No `.github/` — analyze, test, and build all run locally. |

---

## Test coverage

308 tests pass. Logic modules are covered directly; widgets are covered for
render-without-overflow across sizes, edit states, and a 1.3× text scale.

| Area | Covered |
| --- | --- |
| Receipt parser | ✅ [receipt_parser_test.dart](mobile/test/logic/receipt_parser_test.dart) |
| Budget math, insights, events, subscriptions | ✅ [logic_test.dart](mobile/test/logic_test.dart) |
| Student planner | ✅ [student_planner_test.dart](mobile/test/student_planner_test.dart) |
| Derived aggregates, persistence debounce | ✅ [derived_benchmark_test.dart](mobile/test/derived_benchmark_test.dart), [persistence_debounce_test.dart](mobile/test/persistence_debounce_test.dart) |
| All 15 workspace widgets | ✅ [workspace_widgets_test.dart](mobile/test/widget/workspace_widgets_test.dart) |
| Entry flow, screens | ✅ [entry_flow_test.dart](mobile/test/widget/entry_flow_test.dart), [screens_test.dart](mobile/test/widget/screens_test.dart) |
| Auth / Supabase paths | ⚪ Untested — there is no configured project to test against |
| Currency FX fetch | ⚪ Untested — hits a live endpoint, needs a fake client |
