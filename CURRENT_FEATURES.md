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

Last verified against `main` on 2026-08-30: `flutter analyze` clean, 385 tests
passing, `dart format` clean across all 71 files.

Every row below was re-checked against the source on that date, not carried
forward. Four claims were wrong and are corrected — see
[Corrections](#corrections-2026-08-29).

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
| Tab navigation (`IndexedStack`) + push routes | ✅ | Not `go_router` — see [Corrections](#corrections-2026-08-29) |

The dashboard renders the full card stack: balance snapshot, stat grid, budget
range, smart cards, spending pattern, daily planner, location guidance,
suggestions, insight box, subscriptions, event calendar, recent transactions,
and day records.

## Core finance

| Feature | Status | Remaining |
| --- | --- | --- |
| Transactions — add, categorise | ✅ | — |
| Transactions — **edit / delete** | ⚪ | `addTransaction` is the only mutator. No update or remove exists |
| Savings goals — create, contribute | ✅ | — |
| Savings goals — **edit / delete** | ⚪ | No `updateGoal` / `removeGoal` |
| Budget categories — create, update | ✅ | `upsertBudget` covers both |
| Budget categories — **delete** | ⚪ | No `removeBudget` |
| Budget plans — create, finalise, delete | ✅ | — |
| Day plans / daily planner — add, delete | ✅ | — |
| **Fixed liabilities** | ⚪ | Storage key only; no provider, no UI, nothing reads it |
| Manual balance entry, derived stats | ✅ | — |
| Multi-currency with live FX (frankfurter.app) | ✅ | — |
| Persistence (`shared_preferences`, debounced writes) | ✅ | — |

All amounts normalise to USD on input and convert on display, per
`PARITY_SPEC.md` §0. The two conventions the web app got wrong are
deliberately **not** reproduced.

`availableBalance` is derived as `manualBalance + totalIncome - totalSpent`,
floored at zero. The web app omitted income, so recording a salary changed
nothing on screen while recording a coffee did — a deliberate divergence from
`PARITY_SPEC.md` §5, pinned by
[balance_reactivity_test.dart](mobile/test/widget/balance_reactivity_test.dart).
Every consumer — safe-to-spend, daily planner, insight cards, location
guidance, workspace widgets — reads that one getter, so they move together.

## Derived logic

Pure Dart, no Flutter imports, unit-tested independently of the UI.

| Module | Status | Remaining |
| --- | --- | --- |
| [budget_math.dart](mobile/lib/logic/budget_math.dart) | ✅ | — |
| [insights.dart](mobile/lib/logic/insights.dart) — behaviour rules, smart cards | ✅ | — |
| [events.dart](mobile/lib/logic/events.dart) — event calendar | ✅ | — |
| [subscriptions.dart](mobile/lib/logic/subscriptions.dart) — recurring-charge detection | ✅ | — |
| [student_planner.dart](mobile/lib/logic/student_planner.dart) | ✅ | — |
| [receipt_parser.dart](mobile/lib/logic/receipt_parser.dart) | ✅ | Wired to the camera — see [Receipt scanning](#receipt-scanning) |

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

**✅ Built on both platforms.** Listed here because the two share rules but not
code, which is a standing maintenance cost.

| Piece | Mobile | Web |
| --- | --- | --- |
| Parser | ✅ v2 — [receipt_parser.dart](mobile/lib/logic/receipt_parser.dart) | 🟡 frozen at v1 |
| Payment-line / card exclusion, tiered ranking | ✅ | ⚪ |
| `cash - change` + item-sum cross-checks | ✅ | ⚪ |
| Currency identification | ✅ | ⚪ |
| Line-item extraction | ✅ | ⚪ |
| OCR | ✅ ML Kit, native, bundled | ✅ tesseract.js, wasm, CDN-fetched |
| Camera capture | ✅ [receipt_scanner.dart](mobile/lib/services/receipt_scanner.dart) | ✅ [ReceiptScanner.tsx](frontend/src/components/ReceiptScanner.tsx) |
| Rotation retry on a poor read | ✅ | ⚪ |
| **Batch scan from gallery** | ✅ [receipt_batch_queue.dart](mobile/lib/logic/receipt_batch_queue.dart) | ⚪ |
| Review before saving | ✅ Entry sheet, and a batch review screen | ✅ Seeds the entry dialog |
| EXIF capture date | ✅ | ⚪ |
| Duplicate flagging | ✅ | ⚪ |
| Subscription warning | ✅ via `wouldBeSubscription` | ⚪ |
| Receipt image stored | ✅ App-private storage | ⚪ |

**The web parser is deliberately frozen at v1.** It is no longer equivalent to
the mobile one, and the shared-fixture rule that used to keep them honest no
longer applies — see [frontend/README.md](frontend/README.md). Web scanning is
not a current target; if it becomes one, port the mobile parser wholesale
rather than patching v1 forward.

### Batch scanning

Pick several receipts from the gallery, processed three at a time with results
held in input order. **Nothing is written until the batch is confirmed** — rows
are individually editable, retryable, and skippable, and a failed row never
blocks the readable ones. Dates come from EXIF where the photo has it, so a
receipt shot on Tuesday is dated Tuesday rather than the night it was scanned;
where EXIF is absent the fallback is shown rather than applied silently.

**This raises the stakes on the missing delete.** A batch can write ten
transactions at once and there is still no way to remove one — see
[Not started](#not-started).

Web OCR is meaningfully weaker than ML Kit's, and its engine downloads ~10 MB
from a CDN on first use, so the first web scan needs a connection. The captured
image never leaves the device on either platform.

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

---

## Release build

**✅ Complete — signed APKs building and verified.**

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
| Release keystore + `key.properties` wired in | ✅ |
| Signed split-per-ABI APKs verified (`CN=Vansh Kapoor`) | ✅ |

Current build: **v0.1.0 build 1**, versionCode 2001 (arm64). Distribution
process and the rules governing updates are in
[Releasing an APK](README.md#releasing-an-apk).

The `✅` on the release rows was verified against the built APK, not assumed:
the manifest was decoded with `aapt2`, the payload scanned for debug-only
strings, and the signature read with `apksigner`.

---

## Corrections (2026-08-29)

Four rows in this file claimed things the code does not do. Recorded rather
than quietly edited, because anyone who planned work off the old version was
misled.

| Claimed | Reality |
| --- | --- |
| "Transactions — add, **edit, delete**, categorise ✅" | Only add. `FinanceProvider` has no update or remove method for transactions, and no UI offers one |
| "Android hardware back / routing (**`go_router`**) ✅" | `go_router` is in `pubspec.yaml` and **used nowhere**. Navigation is `IndexedStack` for tabs and `MaterialPageRoute` for the budget screen. No `PopScope`/`WillPopScope` anywhere — back is stock Navigator behaviour |
| "**Fixed liabilities** ✅" | Only `PrefsKeys.fixedLiabilities` exists. Nothing reads or writes it — no provider, no logic, no UI |
| "Savings goals ✅" (implying full CRUD) | Create and contribute only |

**Action:** `go_router` should be removed from `pubspec.yaml` or actually
adopted. An unused routing dependency in a shipped APK is dead weight, and its
presence in this file is what made the claim look verified.

---

## Not started

| Feature | Notes |
| --- | --- |
| **Social benchmarks** (`PARITY_SPEC.md` §7) | No code anywhere in `lib/`. Needs the city/course cost table, the private-lobby opt-in (`cash-compass-private-lobby-v1`), the seed challenge, and the leave-lobby control the web app claims but never implemented. |
| **Backend / data sync** | Undecided between the maintainer's Python/FastAPI + MySQL service and finishing Supabase. Until one lands, `mobile/` and `frontend/` hold entirely separate data for the same account. |
| **Themes 2–5** | See [Themes](#themes) above. |
| **Transaction edit / delete** | The single most visible gap, and more urgent since batch scanning landed: a batch can write ten rows at once, and a wrong one can only be undone with Reset All, which wipes everything. `addTransaction` is the only mutator. Anything added must route through `_persist()` so the derived figures stay correct. |
| **Goal and budget-category delete** | Same shape as above. |
| **Fixed liabilities** | Storage key reserved, nothing built. |
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
