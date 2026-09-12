# Financial Literacy Cards — design

## Problem

The app has no in-app financial education content. This adds a small, static
library of money-management tips ("literacy cards"), browsable by category,
with read-tracking so other features (the badges system's "Financial Master"
badge) can react to engagement.

## Scope

`mobile/` only, per [README.md](../../../README.md) — `frontend/` is
reference-only and closed to new features.

## Content

18 cards, verbatim from the source spec, in 5 fixed categories. Stored as a
static Dart list — no user-generated content, no remote fetch.

| Category | Cards |
| --- | --- |
| Food & Delivery | The Daily Drip, Late-Night Craving, Meal Prep Power, Hungry Shopper |
| Subscriptions & Tech | Ghost Subscriptions, Student Discounts, Upgrade Cycle |
| Smart Shopping & Lifestyle | The 24-Hour Rule, Off-Season Steals, Textbook Hack |
| Savings & Future Planning | Micro-Savings, Emergency Cushion, Compound Interest |
| Mindset & Budgeting | The 50/30/20 Guide, Invisible Leaks, The Hour Value, Credit Trap, Wishlist Trick |

Each card is `{id, category, title, body}`. `id` is a stable slug (e.g.
`daily-drip`), used as the read-tracking key and never reused or renumbered.

Money amounts stay exactly as authored (₽), including in the English text —
these are illustrative tips, not tied to the user's real balance or active
display currency. No currency-conversion logic is involved.

## Localization

Title and body go into `lib/l10n/app_en.arb` (one key pair per card,
`literacyCard<Id>Title` / `literacyCard<Id>Body`), mirrored in `app_ru.arb`
with a Russian translation of the wording (numbers/₽ unchanged). Matches how
every other user-facing string in the app is already bilingual.

## State: `LiteracyCardsProvider`

New provider, same shape as the other `ChangeNotifier` stores:

- `Set<String> readCardIds` — persisted at `PrefsKeys.literacyCards`
  (`cash-compass-literacy-cards-v1`), loaded on startup, debounced write on
  change (same `_persist`/`_scheduleWrite`/`flush` pattern as
  `FinanceProvider`).
- `void markRead(String cardId)` — idempotent; a no-op notify is skipped if
  the id is already in the set.
- Registered alongside the other providers in `main.dart`'s `MultiProvider`.

"Read" means the card was opened to its full-screen view, not merely
scrolled past in a list or glimpsed on the rotating workspace card.

## UI

**Workspace widget** — new `WorkspaceWidgetType.literacyTip`, added to the
existing enum (`lib/models/workspace_widget.dart`) and rendered in
`widget_bodies.dart` alongside Manga Status / ASCII Fortune / Chibi Mascot.
Shows one card's title + a truncated body, rotating to a pseudo-random unread
card each time the widget is added or the app is reopened (falls back to any
card once all are read). Tapping it opens the full list screen, deep-linked to
that card.

**Financial Tips screen** — new pushed screen (`lib/screens/financial_tips_screen.dart`,
same pattern as `BudgetPlanScreen`), listing all cards grouped under their
category as section headers, each row showing a read/unread dot. Tapping a
row opens a full-screen card view (title, body, category chip) and calls
`markRead`. Reachable from a new item in the Settings tab's list (a `_Section`
titled with the feature name, containing a single navigation row — matches
how other settings rows are structured).

## Testing

- Unit test for `LiteracyCardsProvider`: load/persist round-trip, `markRead`
  idempotency, debounced write.
- Widget test: Financial Tips screen renders all categories and marks a card
  read after opening it.
- The workspace widget renders without overflow at all three sizes, matching
  the existing `workspace_widgets_test.dart` coverage pattern.

## Out of scope

- `frontend/` (React) gets nothing — matches the "reference only" rule.
- No spaced-repetition, quiz, or content-authoring UI — this is a fixed,
  developer-maintained list.
- Per-card localization beyond English/Russian (no other languages exist in
  the app yet).
