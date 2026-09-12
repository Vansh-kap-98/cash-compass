/// Rewards & Badges — unlock rules.
///
/// Pure Dart, no Flutter imports of its own (though the models it reads
/// transitively pull one in, matching `insights.dart`) — every rule is
/// unit-testable without a widget harness. See
/// `docs/superpowers/specs/2026-09-12-rewards-badges-design.md` for the
/// reasoning behind which badges made this list and which were dropped.
library;

import '../models/budget_category.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';
import '../models/wishlist_item.dart';

/// The four groupings badges are organised under. Only one of the source
/// spec's "Social & Special" badges survived triage (Financial Master), so
/// that category is renamed to reflect what actually lives in it.
enum AchievementCategory { savings, budgetControl, habitStreak, special }

/// One badge definition. Content-free, like [LiteracyCard] — titles and
/// requirement text live in `l10n/presenters.dart`.
class AchievementBadge {
  const AchievementBadge({required this.id, required this.category});

  /// Stable slug. Never reused or renumbered: it is the persisted
  /// unlocked-badge key in `AchievementsProvider`.
  final String id;
  final AchievementCategory category;
}

/// All badges, in display order within each category.
///
/// Dropped from the source spec, and why:
/// - Pack Leader, Podium Finish, Generous Heart, True North — need shared
///   goals, friend leaderboards, or multi-device sync, none of which exist.
///   Tracked as follow-up issues rather than built here.
/// - Momentum Build — folded into Daily Driver / 30-Day Legend, which are the
///   same streak mechanism at different thresholds.
///
/// Reinterpreted rather than dropped:
/// - Fortress — "emergency fund" isn't a concept the data model has, so this
///   reads as any single goal reaching [fortressThresholdUsd].
/// - Speed Demon — needs a goal target date, which [SavingsGoal.targetDate]
///   now provides.
///
/// Shipped in a follow-up pass once their prerequisite feature landed:
/// - Iron Shield — needed a withdrawal action, which didn't exist when the
///   first batch of badges shipped. `FinanceProvider.withdrawFromGoal` and
///   [SavingsGoal.createdAt] now make it meaningful instead of vacuously true.
/// - Zero Impulse — needed a wishlist feature, which didn't exist either.
///   `WishlistProvider` now backs it.
const List<AchievementBadge> achievementBadges = [
  AchievementBadge(id: 'first-seed', category: AchievementCategory.savings),
  AchievementBadge(id: 'goal-crusher', category: AchievementCategory.savings),
  AchievementBadge(id: 'fortress', category: AchievementCategory.savings),
  AchievementBadge(id: 'speed-demon', category: AchievementCategory.savings),
  AchievementBadge(id: 'iron-shield', category: AchievementCategory.savings),
  AchievementBadge(
    id: 'tracking-ninja',
    category: AchievementCategory.budgetControl,
  ),
  AchievementBadge(
    id: 'master-balancer',
    category: AchievementCategory.budgetControl,
  ),
  AchievementBadge(
    id: 'under-budget',
    category: AchievementCategory.budgetControl,
  ),
  AchievementBadge(
    id: 'category-boss',
    category: AchievementCategory.budgetControl,
  ),
  AchievementBadge(
    id: 'zero-impulse',
    category: AchievementCategory.budgetControl,
  ),
  AchievementBadge(
    id: 'daily-driver',
    category: AchievementCategory.habitStreak,
  ),
  AchievementBadge(
    id: 'thirty-day-legend',
    category: AchievementCategory.habitStreak,
  ),
  AchievementBadge(
    id: 'payday-first',
    category: AchievementCategory.habitStreak,
  ),
  AchievementBadge(
    id: 'unsubscriber',
    category: AchievementCategory.habitStreak,
  ),
  AchievementBadge(
    id: 'night-owl-tracker',
    category: AchievementCategory.habitStreak,
  ),
  AchievementBadge(
    id: 'financial-master',
    category: AchievementCategory.special,
  ),
];

/// USD threshold for First Seed — "saved a first $500" in this app's own
/// economy (goal targets and the app's example amounts are already
/// unit-less/USD-scale; this does not attempt to convert the source spec's
/// ₽500 through a real exchange rate).
const double firstSeedThresholdUsd = 500;

/// USD threshold for Fortress, reinterpreted as any single goal reaching this
/// balance rather than a distinct "emergency fund" concept.
const double fortressThresholdUsd = 15000;

/// How many days ahead of its target date a goal must complete to count as
/// Speed Demon, per the source spec.
const int speedDemonAheadDays = 5;

/// Consecutive-day streak needed for Daily Driver.
const int dailyDriverStreakDays = 14;

/// Consecutive-day streak needed for 30-Day Legend.
const int thirtyDayLegendStreakDays = 30;

/// Cards read to unlock Financial Master, per the source spec.
const int financialMasterCardsRead = 15;

/// How long a goal must exist, and how long since the last withdrawal from
/// any goal, for Iron Shield — "a full month without touching your pot".
const int ironShieldQuietDays = 30;

/// How long a wishlist item must sit before a "skip" counts toward Zero
/// Impulse, per the source spec.
const int zeroImpulseWaitHours = 48;

/// Everything the unlock rules need, gathered in one place so
/// [evaluateUnlockedBadges] stays a pure function of its inputs.
class AchievementInputs {
  const AchievementInputs({
    required this.goals,
    required this.budgets,
    required this.transactions,
    required this.readLiteracyCardCount,
    required this.activityDates,
    required this.savingsActivityDates,
    required this.canceledSubscriptionSignatures,
    this.lastWithdrawalDate,
    this.wishlistItems = const [],
    this.now,
  });

  final List<SavingsGoal> goals;
  final List<BudgetCategory> budgets;
  final List<FinanceTransaction> transactions;

  /// From `LiteracyCardsProvider.readCardIds.length`.
  final int readLiteracyCardCount;

  /// `yyyy-MM-dd` days the app recorded any activity on, from
  /// `AchievementsProvider`'s own log.
  final List<String> activityDates;

  /// `yyyy-MM-dd` days a goal contribution happened, from the same log.
  final List<String> savingsActivityDates;

  /// `merchantSignature` values the user marked as canceled.
  final Set<String> canceledSubscriptionSignatures;

  /// ISO-8601 timestamp of the most recent withdrawal from any goal, from
  /// `AchievementsProvider`'s own log. Null if none has ever happened.
  final String? lastWithdrawalDate;

  /// From `WishlistProvider.items`.
  final List<WishlistItem> wishlistItems;

  /// Injectable for tests; defaults to the real current time.
  final DateTime? now;
}

/// Returns the set of badge ids that should be unlocked given [inputs].
///
/// Badges never re-lock: `AchievementsProvider` unions this result with what
/// was already unlocked, so a goal being edited back down, say, cannot revoke
/// a badge already earned.
Set<String> evaluateUnlockedBadges(AchievementInputs inputs) {
  final now = inputs.now ?? DateTime.now();
  final unlocked = <String>{};

  final lifetimeSaved =
      inputs.goals.fold<double>(0, (sum, g) => sum + g.current);
  if (lifetimeSaved >= firstSeedThresholdUsd) unlocked.add('first-seed');

  if (inputs.goals.any((g) => g.isComplete)) unlocked.add('goal-crusher');

  if (inputs.goals.any((g) => g.current >= fortressThresholdUsd)) {
    unlocked.add('fortress');
  }

  if (_hasSpeedDemonGoal(inputs.goals)) unlocked.add('speed-demon');

  if (_hasIronShieldGoal(inputs.goals, inputs.lastWithdrawalDate, now)) {
    unlocked.add('iron-shield');
  }

  if (_isTrackingNinja(inputs.transactions)) unlocked.add('tracking-ninja');

  if (_hasZeroImpulseSkip(inputs.wishlistItems)) unlocked.add('zero-impulse');

  final monthEval = _previousMonthBudgetEvaluation(
    budgets: inputs.budgets,
    transactions: inputs.transactions,
    now: now,
  );
  if (monthEval.withinEveryCategory) unlocked.add('master-balancer');
  if (monthEval.under10PercentOfTotal) unlocked.add('under-budget');

  if (inputs.budgets.length >= 5) unlocked.add('category-boss');

  final activityStreak = _consecutiveDayStreak(inputs.activityDates, now);
  if (activityStreak >= dailyDriverStreakDays) unlocked.add('daily-driver');
  if (activityStreak >= thirtyDayLegendStreakDays) {
    unlocked.add('thirty-day-legend');
  }

  if (_hasPaydayFirst(inputs.transactions, inputs.savingsActivityDates)) {
    unlocked.add('payday-first');
  }

  if (inputs.canceledSubscriptionSignatures.isNotEmpty) {
    unlocked.add('unsubscriber');
  }

  if (inputs.transactions.any(_isLateNight)) {
    unlocked.add('night-owl-tracker');
  }

  if (inputs.readLiteracyCardCount >= financialMasterCardsRead) {
    unlocked.add('financial-master');
  }

  return unlocked;
}

bool _hasSpeedDemonGoal(List<SavingsGoal> goals) {
  for (final g in goals) {
    final target = g.targetDate;
    if (!g.isComplete || target == null) continue;
    final targetDate = DateTime.tryParse(target);
    final completedAt = g.completedAt;
    if (targetDate == null || completedAt == null) continue;
    final completedDate = DateTime.tryParse(completedAt);
    if (completedDate == null) continue;
    final aheadBy = targetDate.difference(completedDate).inDays;
    if (aheadBy >= speedDemonAheadDays) return true;
  }
  return false;
}

/// True once at least one goal has existed quietly for [ironShieldQuietDays]:
/// created that long ago, and no withdrawal (from *any* goal) has landed
/// inside that same trailing window.
///
/// Goals created before `SavingsGoal.createdAt` existed (null) never qualify
/// — there is no way to know how old they are, so they are silently excluded
/// rather than guessed at.
bool _hasIronShieldGoal(
  List<SavingsGoal> goals,
  String? lastWithdrawalDate,
  DateTime now,
) {
  final lastWithdrawal =
      lastWithdrawalDate == null ? null : DateTime.tryParse(lastWithdrawalDate);
  if (lastWithdrawal != null &&
      now.difference(lastWithdrawal).inDays < ironShieldQuietDays) {
    return false;
  }

  for (final g in goals) {
    final createdAt = g.createdAt;
    if (createdAt == null) continue;
    final created = DateTime.tryParse(createdAt);
    if (created == null) continue;
    if (now.difference(created).inDays >= ironShieldQuietDays) return true;
  }
  return false;
}

/// True once some wishlist item was added, left alone for at least
/// [zeroImpulseWaitHours], and then explicitly skipped rather than bought.
bool _hasZeroImpulseSkip(List<WishlistItem> items) {
  for (final item in items) {
    if (item.status != WishlistStatus.skipped) continue;
    final resolvedAt = item.resolvedAt;
    if (resolvedAt == null) continue;
    final added = DateTime.tryParse(item.addedAt);
    final resolved = DateTime.tryParse(resolvedAt);
    if (added == null || resolved == null) continue;
    if (resolved.difference(added).inHours >= zeroImpulseWaitHours) return true;
  }
  return false;
}

/// A rough read on "categorised deliberately": every expense ever recorded
/// has moved off the silent `'Other'` fallback, and there is enough history
/// (14 distinct days with expense activity) for that to mean something.
///
/// This is a simplification of the source spec's "14 days straight" — the app
/// has no record of which category a transaction *would* have defaulted to,
/// only the final stored value, so a true consecutive-streak version isn't
/// derivable without new per-transaction state.
bool _isTrackingNinja(List<FinanceTransaction> transactions) {
  final expenseDays = <String>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    expenseDays.add(t.date);
    if (t.category == 'Other') return false;
  }
  return expenseDays.length >= 14;
}

class _MonthEvaluation {
  const _MonthEvaluation({
    required this.withinEveryCategory,
    required this.under10PercentOfTotal,
  });

  final bool withinEveryCategory;
  final bool under10PercentOfTotal;
}

/// Evaluates the most recently completed calendar month's spend against
/// today's budget limits. Past months are not evaluated against whatever
/// limits were live at the time, since only the current limit is stored.
_MonthEvaluation _previousMonthBudgetEvaluation({
  required List<BudgetCategory> budgets,
  required List<FinanceTransaction> transactions,
  required DateTime now,
}) {
  if (budgets.isEmpty) {
    return const _MonthEvaluation(
      withinEveryCategory: false,
      under10PercentOfTotal: false,
    );
  }

  final firstOfThisMonth = DateTime(now.year, now.month, 1);
  final lastMonth = DateTime(firstOfThisMonth.year, firstOfThisMonth.month - 1);
  final prefix = '${lastMonth.year.toString().padLeft(4, '0')}-'
      '${lastMonth.month.toString().padLeft(2, '0')}';

  final spentByCategory = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense || !t.date.startsWith(prefix)) continue;
    spentByCategory[t.category] = (spentByCategory[t.category] ?? 0) + t.amount;
  }

  var withinEvery = true;
  var totalSpent = 0.0;
  var totalLimit = 0.0;
  for (final b in budgets) {
    final spent = spentByCategory[b.name] ?? 0;
    totalSpent += spent;
    totalLimit += b.monthlyLimit;
    if (spent > b.monthlyLimit) withinEvery = false;
  }

  final under10Percent = totalLimit > 0 && totalSpent <= totalLimit * 0.9;
  return _MonthEvaluation(
    withinEveryCategory: withinEvery,
    under10PercentOfTotal: under10Percent,
  );
}

bool _hasPaydayFirst(
  List<FinanceTransaction> transactions,
  List<String> savingsActivityDates,
) {
  if (savingsActivityDates.isEmpty) return false;
  final savingsDays = savingsActivityDates.toSet();
  for (final t in transactions) {
    if (t.type == TransactionType.income && savingsDays.contains(t.date)) {
      return true;
    }
  }
  return false;
}

bool _isLateNight(FinanceTransaction t) {
  final createdAt = t.createdAt;
  if (createdAt == null) return false;
  final parsed = DateTime.tryParse(createdAt);
  if (parsed == null) return false;
  return parsed.hour >= 22 || parsed.hour < 5;
}

/// Longest run of consecutive calendar days in [isoDates], counted backward
/// from [now]. Same shape as the Growth Gem widget's Bloom Streaks
/// (`PARITY_SPEC.md` §8): a clean consecutive-day count, not a fuzzy one.
int _consecutiveDayStreak(List<String> isoDates, DateTime now) {
  if (isoDates.isEmpty) return 0;
  final unique = isoDates.toSet();
  var streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  while (true) {
    final iso = '${cursor.year.toString().padLeft(4, '0')}-'
        '${cursor.month.toString().padLeft(2, '0')}-'
        '${cursor.day.toString().padLeft(2, '0')}';
    if (!unique.contains(iso)) break;
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
