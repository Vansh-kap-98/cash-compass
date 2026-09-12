# Rewards & Badges — design

## Problem

The source request asked for 21 badges across four categories (Savings,
Budget Control, Habit & Streak, Social & Special). Most of the "Social &
Special" ones, and a few others, need product features this app doesn't
have. This documents which badges shipped, which were dropped, and why —
see [achievementBadges](../../../mobile/lib/logic/badges.dart) for the
authoritative list.

## Scope

`mobile/` only, per [README.md](../../../README.md).

## Triage

| Outcome | Badges | Reason |
| --- | --- | --- |
| Shipped as designed | Goal Crusher, Category Boss, Night Owl Tracker, First Seed, Master Balancer, Under Budget, Tracking Ninja | Derivable from existing `FinanceProvider` state with no new persisted fields |
| Shipped with a small, self-contained addition | Daily Driver, 30-Day Legend, Payday First, Unsubscriber | Need a small log `AchievementsProvider` owns itself (activity dates, a canceled-subscription set) — nothing else is touched |
| Reinterpreted | Fortress → any single goal reaching `fortressThresholdUsd` (no "emergency fund" concept exists); Speed Demon → needs `SavingsGoal.targetDate`, added as a small backward-compatible model field | The literal badge as specified needs a concept the data model doesn't have; a narrow addition made it buildable anyway |
| Dropped | Iron Shield (no withdrawal action exists to violate — would be vacuously true forever), Zero Impulse (needs a wishlist feature from scratch), Pack Leader / Podium Finish / Generous Heart / True North (need shared goals, friend leaderboards, gift goals, or multi-device sync — none exist), Momentum Build (folded into Daily Driver / 30-Day Legend, the same mechanism at different thresholds) | Would require building an unrelated feature just to support one badge |

14 badges shipped.

## Data model

`AchievementBadge` (id, `AchievementCategory`) is static content, same shape
as `LiteracyCard` — titles and descriptions live in `l10n/presenters.dart`,
not in the model.

`AchievementInputs` (`lib/logic/badges.dart`) gathers everything the unlock
rules read: goals, budgets, transactions, the literacy-card read count, and
three small logs described below. `evaluateUnlockedBadges(inputs)` is a pure
function returning the set of badge ids that should be unlocked — unit
tested in `test/logic/badges_test.dart` with no widget harness needed.

## State: `AchievementsProvider`

Same persistence shape as `FinanceProvider` (debounced write, `flush()` on
app pause). Holds:

- `unlockedBadgeIds` (`Set<String>`, persisted) — a badge already earned
  stays earned even if the underlying condition later stops holding (e.g. a
  goal's balance can only go up today, but the rule is written defensively).
- `activityDates` / `savingsActivityDates` (`List<String>`, persisted) — days
  the app recorded any change, and days a goal contribution happened,
  respectively. Diffed against a previous-goal-balance snapshot kept
  in-memory only (not persisted, so a cold start never misattributes
  pre-existing balances as "today's" activity).
- `canceledSubscriptionSignatures` (`Set<String>`, persisted) — keyed by
  `merchantSignature`, set by a new "mark as canceled" action on the
  Subscriptions card, which also hides canceled entries from that card.

`recompute()` is called whenever `FinanceProvider` or `LiteracyCardsProvider`
change, via a listener registered once in `DashboardScreen` (the one
long-lived shell widget) — the codebase has no existing
`ChangeNotifierProxyProvider` pattern to hook into, so this mirrors the
existing single-choke-point pattern `DashboardScreen` already uses for
flushing stores on pause, rather than introducing a new one.

## Model changes

`SavingsGoal` gains two nullable fields, both backward-compatible with goals
saved before this shipped:

- `targetDate` (ISO date) — set once at goal creation from the timeframe the
  user already picks in `SetGoalSheet` (no new UI).
- `completedAt` (ISO timestamp) — stamped once by
  `FinanceProvider.contributeToGoal` the moment a goal first reaches its
  target; never overwritten afterward.

## UI

"Achievements" screen (pushed, reachable from a new Settings row), listing
every badge grouped by category, greyed out when locked with its
description shown as the requirement text. A snackbar announces a newly
unlocked badge from wherever the user happens to be, driven by the same
`DashboardScreen` listener that calls `recompute()`.

## Currency note

First Seed ($500) and Fortress ($15,000) keep the numbers from the source
spec but read them as USD against the app's internal USD ledger, rather than
converting the spec's ₽ figures through a real exchange rate — the app's own
example amounts (e.g. the goal-target field's `5000` hint) are already
unit-less on this same scale. If a different difficulty is wanted, both are
single named constants in `lib/logic/badges.dart`.

## Testing

- `test/logic/badges_test.dart` — pure unit tests per badge, including edge
  cases (streak gaps, the exact Speed Demon boundary, month-boundary budget
  math).
- `test/achievements_persistence_test.dart` — debounced persistence,
  idempotent re-marking, and the "never re-locks" guarantee.
- The shared widget-test harness (`test/widget/harness.dart`) now registers
  both new providers, since the dashboard (and therefore the Subscriptions
  card, which reads `AchievementsProvider`) renders in several existing
  widget tests.
