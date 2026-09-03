/// Rule-based spending insights.
///
/// Ports `lib/behaviorInsights.ts`, `InsightBox.tsx`, and
/// `insights/SmartCards.tsx`. Pure Dart — no Flutter imports — so every rule is
/// unit-testable. See `PARITY_SPEC.md`.
library;

import '../models/budget_category.dart';
import '../models/savings_goal.dart';
import '../models/transaction.dart';

/// Matches merchants that are usually recurring subscriptions.
final RegExp subscriptionPattern =
    RegExp(r'netflix|spotify|subscription|prime|youtube', caseSensitive: false);

/// Matches small discretionary spending the Smart Cards watch.
final RegExp discretionaryPattern =
    RegExp(r'coffee|cafe|latte|snack|food|entertainment', caseSensitive: false);

/// Matches travel-flavoured goals, used to suggest where to divert savings.
final RegExp travelGoalPattern =
    RegExp(r'travel|trip|goa|sochi', caseSensitive: false);

// ---------------------------------------------------------------- behaviour

/// A detected pattern in unplanned spending, e.g. Friday nights.
///
/// Carries the weekday as a number rather than a name, and no sentence: the
/// wording is a presentation concern and lives in the localisations. See
/// `lib/l10n/presenters.dart`.
class BehaviorInsight {
  const BehaviorInsight({
    required this.weekday,
    required this.tag,
    required this.isNight,
    required this.count,
  });

  /// ISO weekday, 1 = Monday through 7 = Sunday, matching [DateTime.weekday].
  final int weekday;
  final ReasonTag tag;
  final bool isNight;
  final int count;
}

/// Night is 18:00 onwards or before 05:00, matching the web app.
bool _isNightHour(int hour) => hour >= 18 || hour < 5;

/// Finds the strongest weekday + reason + time-of-day cluster.
///
/// Returns null until there are at least two tagged spontaneous expenses and
/// one bucket has at least two — below that the "pattern" is noise.
BehaviorInsight? behaviorInsight(List<FinanceTransaction> transactions) {
  // Counters keyed by bucket, with the winning bucket built once at the end.
  // The previous version allocated a fresh BehaviorInsight for every tag on
  // every matching transaction just to increment a number.
  final counts = <String, int>{};
  final meta = <String, ({int weekday, ReasonTag tag, bool night})>{};
  var spontaneousCount = 0;

  for (final t in transactions) {
    if (!t.isExpense || !t.isUnplanned || t.reasonTags.isEmpty) continue;
    spontaneousCount++;

    final stamp = t.createdAt;
    // Only the date drives the weekday, and the hour is two characters at a
    // known offset in an ISO timestamp — parsing the full stamp was the most
    // expensive step here.
    final day = DateTime.tryParse(t.date);
    if (day == null) continue;
    final hour = (stamp != null && stamp.length >= 13)
        ? int.tryParse(stamp.substring(11, 13)) ?? 0
        : 0;

    final weekday = day.weekday;
    final night = _isNightHour(hour);

    for (final tag in t.reasonTags) {
      final key = '$weekday-${tag.name}-$night';
      counts[key] = (counts[key] ?? 0) + 1;
      meta[key] ??= (weekday: weekday, tag: tag, night: night);
    }
  }

  if (spontaneousCount < 2 || counts.isEmpty) return null;

  var bestKey = '';
  var bestCount = 0;
  counts.forEach((key, count) {
    if (count > bestCount) {
      bestCount = count;
      bestKey = key;
    }
  });

  if (bestCount < 2) return null;
  final m = meta[bestKey]!;
  return BehaviorInsight(
    weekday: m.weekday,
    tag: m.tag,
    isNight: m.night,
    count: bestCount,
  );
}

// ------------------------------------------------------------- suggestions

/// One entry in the Smart Suggestions list, as data.
///
/// The rules below decide *which* suggestion fires and with what figures; the
/// wording is localised at render time by `lib/l10n/presenters.dart`. Amounts
/// stay in USD like everything else in this layer, so the presenter can format
/// them in whichever currency is active — the previous version baked
/// "… USD" into the sentence and showed a dollar figure to someone working in
/// rupees.
sealed class Suggestion {
  const Suggestion();
}

/// The largest expense category this month, and what a 10% trim would free.
class WatchCategorySuggestion extends Suggestion {
  const WatchCategorySuggestion({
    required this.category,
    required this.savingUsd,
  });

  final String category;
  final double savingUsd;
}

/// A category budget at or past 80% of its monthly limit.
class BudgetAlertSuggestion extends Suggestion {
  const BudgetAlertSuggestion({
    required this.category,
    required this.percentUsed,
  });

  final String category;
  final int percentUsed;
}

/// Merchant names matching [subscriptionPattern], at most three.
class AuditSubscriptionsSuggestion extends Suggestion {
  const AuditSubscriptionsSuggestion(this.names);
  final List<String> names;
}

/// The neutral fallback, so the card is never empty.
class TrackForSevenDaysSuggestion extends Suggestion {
  const TrackForSevenDaysSuggestion();
}

/// Up to three rule-based suggestions.
///
/// Order matters and mirrors the web app: top-category trim, budget alert at
/// 80% of a monthly limit, then a subscription audit. If none fire, a neutral
/// fallback keeps the card from looking broken.
List<Suggestion> smartSuggestions({
  required List<FinanceTransaction> transactions,
  required List<BudgetCategory> budgets,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final suggestions = <Suggestion>[];

  // A string prefix rather than parsing every date. `date` is ISO
  // `yyyy-MM-dd`, so this is exact, and it avoids a DateTime allocation per
  // transaction on a path that runs for every card rebuild.
  final monthPrefix = '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}';

  final byCategory = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense || !t.isInMonthPrefix(monthPrefix)) continue;
    byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
  }

  if (byCategory.isNotEmpty) {
    final top = byCategory.entries.reduce((a, b) => b.value > a.value ? b : a);
    final saving = top.value * 0.1;
    suggestions.add(WatchCategorySuggestion(
      category: top.key,
      savingUsd: saving,
    ));
  }

  for (final budget in budgets) {
    final spent = byCategory[budget.name] ?? 0;
    if (budget.monthlyLimit <= 0) continue;
    if (spent / budget.monthlyLimit >= 0.8) {
      suggestions.add(BudgetAlertSuggestion(
        category: budget.name,
        percentUsed: (spent / budget.monthlyLimit * 100).round(),
      ));
      break;
    }
  }

  // Stops once three distinct names are found — the message only shows three,
  // and matching a regex against every transaction name is the most expensive
  // step in this function.
  final subs = <String>{};
  for (final t in transactions) {
    if (subs.length >= 3) break;
    if (!t.isExpense) continue;
    if (subscriptionPattern.hasMatch(t.name)) subs.add(t.name);
  }
  if (subs.isNotEmpty) {
    suggestions.add(AuditSubscriptionsSuggestion(subs.take(3).toList()));
  }

  if (suggestions.isEmpty) {
    suggestions.add(const TrackForSevenDaysSuggestion());
  }

  return suggestions.take(3).toList();
}

// -------------------------------------------------------------- smart cards

/// The discretionary-spend watch shown on the dashboard.
class SmartCard {
  const SmartCard({
    required this.watching,
    required this.todayAmount,
    required this.shareOfLimit,
    required this.annualised,
    this.divertGoalName,
  });

  /// True when today's discretionary spend is still comfortably low.
  final bool watching;
  final double todayAmount;

  /// Fraction of the daily limit consumed, 0..n.
  final double shareOfLimit;

  /// What this rate of spending would cost over a year.
  final double annualised;

  /// A travel-ish goal worth diverting the money to, if one exists.
  final String? divertGoalName;
}

/// Evaluates today's discretionary spending against the daily limit.
///
/// Fires the alert state above 40% of the limit, matching the web app.
SmartCard smartCard({
  required List<FinanceTransaction> transactions,
  required List<SavingsGoal> goals,
  required double? dailyLimit,
  String? todayIsoDate,
}) {
  final today = todayIsoDate ?? _todayIso();
  final amount = transactions
      .where((t) =>
          t.isExpense &&
          t.date == today &&
          (discretionaryPattern.hasMatch(t.name) ||
              discretionaryPattern.hasMatch(t.category)))
      .fold(0.0, (sum, t) => sum + t.amount);

  final share =
      (dailyLimit == null || dailyLimit <= 0) ? 0.0 : amount / dailyLimit;

  String? divert;
  for (final g in goals) {
    if (travelGoalPattern.hasMatch(g.name)) {
      divert = g.name;
      break;
    }
  }

  return SmartCard(
    watching: share <= 0.4,
    todayAmount: amount,
    shareOfLimit: share,
    annualised: amount * 365,
    divertGoalName: divert,
  );
}

String _todayIso() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ------------------------------------------------------------ goal insights

/// One line of narrative guidance on the Goals tab, as data.
///
/// Same split as [Suggestion]: the rule picks the line and its numbers, the
/// presenter supplies the words.
sealed class GoalInsight {
  const GoalInsight();
}

/// Shown until there is enough history for the rules below to say anything.
class GoalInsightEmpty extends GoalInsight {
  const GoalInsightEmpty();
}

/// The largest category and its share of all spending.
class GoalInsightTopShare extends GoalInsight {
  const GoalInsightTopShare({required this.category, required this.percent});
  final String category;
  final int percent;
}

/// The two largest categories and their combined share.
class GoalInsightTopTwo extends GoalInsight {
  const GoalInsightTopTwo({
    required this.first,
    required this.second,
    required this.percent,
  });

  final String first;
  final String second;
  final int percent;
}

/// Standing advice, shown regardless of the figures.
class GoalInsightAutomate extends GoalInsight {
  const GoalInsightAutomate();
}

/// Standing advice, shown regardless of the figures.
class GoalInsightReviewWeekly extends GoalInsight {
  const GoalInsightReviewWeekly();
}

/// Narrative suggestions derived from the top spending categories.
///
/// Port of the four template strings in `GoalsInsights.tsx`.
List<GoalInsight> goalInsights(List<FinanceTransaction> transactions) {
  final byCategory = <String, double>{};
  var total = 0.0;
  for (final t in transactions) {
    if (!t.isExpense) continue;
    byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    total += t.amount;
  }
  if (byCategory.isEmpty || total <= 0) {
    return const [GoalInsightEmpty()];
  }

  final sorted = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  final second = sorted.length > 1 ? sorted[1] : null;

  return [
    GoalInsightTopShare(
      category: top.key,
      percent: (top.value / total * 100).round(),
    ),
    if (second != null)
      GoalInsightTopTwo(
        first: top.key,
        second: second.key,
        percent: ((top.value + second.value) / total * 100).round(),
      ),
    const GoalInsightAutomate(),
    const GoalInsightReviewWeekly(),
  ];
}
