# Goal withdrawals and Wishlist — design

## Problem

Two badges from the original Rewards & Badges request (see
[2026-09-12-rewards-badges-design.md](2026-09-12-rewards-badges-design.md))
were dropped because they needed features this app didn't have: Iron Shield
needed a way to withdraw from a savings goal, and Zero Impulse needed a
wishlist. This follow-up builds both, then reinstates the two badges.

## Scope

`mobile/` only, stacked on `feat/literacy-cards-and-badges` (this branch
depends on `AchievementsProvider` and `lib/logic/badges.dart` from that
branch, which hasn't merged yet).

## Goal withdrawals

`FinanceProvider.withdrawFromGoal(goalId, amount)` mirrors
`contributeToGoal`: subtracts from `current`, floored at zero (there's no
overdraft), debounced-persisted the same way. A "Withdraw" button sits next
to the existing "Add $100" button on each goal card in the Goals tab,
disabled when the goal has nothing to withdraw.

`SavingsGoal` gains `createdAt` (ISO-8601, set once at creation), needed to
tell how long a goal has existed — nothing else reads it.

**Iron Shield unlocks** when at least one goal is 30+ days old
(`createdAt`) and no withdrawal (from *any* goal) has happened in that same
trailing 30-day window. `AchievementsProvider` tracks `lastWithdrawalDate` by
diffing each goal's `current` on every `recompute()` pass — the same
mechanism it already uses to detect a contribution, just watching the other
direction. Goals created before `createdAt` existed (null) can't qualify;
they're silently excluded rather than guessed at.

## Wishlist

New `WishlistItem` model (id, name, amount in USD, `addedAt`, `status` —
pending/purchased/skipped, `resolvedAt`) and `WishlistProvider`
(add/markPurchased/markSkipped), persisted the same way every other store is.
A new "Wishlist" screen (reachable from Settings) lists items with two
actions on a pending one; a resolved item just shows its status.

**Zero Impulse unlocks** when any item's `resolvedAt - addedAt >= 48 hours`
and its status is `skipped` — buying it doesn't count, only skipping does,
per the source spec.

## Wiring

`AchievementsProvider.recompute()` gained two inputs:
`wishlistItems` (passed straight through to `evaluateUnlockedBadges`) and the
withdrawal-date diffing described above. `DashboardScreen`'s existing
listener (the single place badges get re-evaluated from) now also listens to
`WishlistProvider`.

## Testing

- `test/goal_withdrawal_test.dart` — floor-at-zero, invalid amounts ignored,
  `completedAt` survives a withdrawal.
- `test/wishlist_provider_test.dart` — persistence round-trip, invalid items
  ignored, a resolved item can't be re-resolved.
- `test/logic/badges_test.dart` — new cases for Iron Shield (age + recent
  withdrawal + missing `createdAt`) and Zero Impulse (the 48-hour boundary,
  purchased vs. skipped, still-pending).

## Out of scope

Pack Leader, Podium Finish, Generous Heart, and True North still need
features well beyond this app's current shape (shared goals, friend
leaderboards, gift goals, multi-device sync via a configured Supabase
project) and are filed as separate follow-up issues rather than attempted
here.
