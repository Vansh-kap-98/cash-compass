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
class BehaviorInsight {
  const BehaviorInsight({
    required this.weekday,
    required this.tag,
    required this.isNight,
    required this.count,
  });

  final String weekday;
  final ReasonTag tag;
  final bool isNight;
  final int count;

  String get message =>
      'Your spontaneous spending clusters around $weekday'
      '${isNight ? ' nights' : ' daytimes'} — '
      'mostly ${tag.name} purchases ($count so far).';
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

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
  final meta = <String, ({String weekday, ReasonTag tag, bool night})>{};
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

    final weekday = _weekdayNames[day.weekday - 1];
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

/// One entry in the Smart Suggestions list.
class Suggestion {
  const Suggestion(this.title, this.body);
  final String title;
  final String body;
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
    suggestions.add(Suggestion(
      'Watch ${top.key}',
      'It is your largest category this month. Trimming 10% would free about '
          '${saving.toStringAsFixed(2)} USD.',
    ));
  }

  for (final budget in budgets) {
    final spent = byCategory[budget.name] ?? 0;
    if (budget.monthlyLimit <= 0) continue;
    if (spent / budget.monthlyLimit >= 0.8) {
      suggestions.add(Suggestion(
        '${budget.name} budget alert',
        'You have used ${(spent / budget.monthlyLimit * 100).round()}% of this '
            'month\'s limit.',
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
    suggestions.add(Suggestion(
      'Audit your subscriptions',
      'Recurring charges detected: ${subs.take(3).join(', ')}.',
    ));
  }

  if (suggestions.isEmpty) {
    suggestions.add(const Suggestion(
      'Track for 7 days',
      'Add a week of entries and personalised suggestions will appear here.',
    ));
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

/// Narrative suggestions derived from the top spending categories.
///
/// Port of the four template strings in `GoalsInsights.tsx`.
List<String> goalInsights(List<FinanceTransaction> transactions) {
  final byCategory = <String, double>{};
  var total = 0.0;
  for (final t in transactions) {
    if (!t.isExpense) continue;
    byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    total += t.amount;
  }
  if (byCategory.isEmpty || total <= 0) {
    return const [
      'Add a few expenses and personalised guidance will appear here.',
    ];
  }

  final sorted = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  final second = sorted.length > 1 ? sorted[1] : null;
  final topShare = (top.value / total * 100).round();

  return [
    '${top.key} is $topShare% of your spending. A 10% trim there moves your '
        'goals faster than cutting anywhere else.',
    if (second != null)
      'Together, ${top.key} and ${second.key} account for '
          '${((top.value + second.value) / total * 100).round()}% of outgoings.',
    'Automating a transfer on the day you get paid protects savings before '
        'spending starts.',
    'Reviewing one category a week is more sustainable than cutting everything '
        'at once.',
  ];
}
