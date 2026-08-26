/// Student survival, social budgeting, loan runway, and streak calculations.
///
/// Port of `StudentPlannerHub.tsx` — 399 lines that were written but never
/// imported, so no user ever saw them. Pure Dart, fully unit-tested.
library;

import '../models/json_utils.dart';
import '../models/transaction.dart';

/// How often an income stream pays out.
enum IncomeCadence { oneTime, weekly, monthly }

extension IncomeCadenceLabel on IncomeCadence {
  String get label => switch (this) {
        IncomeCadence.oneTime => 'One-time',
        IncomeCadence.weekly => 'Weekly',
        IncomeCadence.monthly => 'Monthly',
      };
}

/// Money coming in over the planning horizon. [amount] is USD.
class IncomeStream {
  const IncomeStream({
    required this.id,
    required this.name,
    required this.amount,
    required this.cadence,
  });

  final String id;
  final String name;
  final double amount;
  final IncomeCadence cadence;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'cadence': cadence.name,
      };

  factory IncomeStream.fromJson(Map<String, dynamic> j) => IncomeStream(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Income',
        amount: asDouble(j['amount']),
        cadence: enumByName(
            IncomeCadence.values, j['cadence'], IncomeCadence.weekly),
      );
}

/// A locked-in bill. [amount] is USD.
class FixedCost {
  const FixedCost({
    required this.id,
    required this.name,
    required this.amount,
  });

  final String id;
  final String name;
  final double amount;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'amount': amount};

  factory FixedCost.fromJson(Map<String, dynamic> j) => FixedCost(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Cost',
        amount: asDouble(j['amount']),
      );
}

/// A planned social outing with a cost range. Amounts are USD.
class SocialPlan {
  const SocialPlan({
    required this.id,
    required this.title,
    required this.date,
    required this.lowEstimate,
    required this.realisticEstimate,
    required this.stretchEstimate,
    required this.splitCount,
    this.note,
  });

  final String id;
  final String title;
  final String date;
  final double lowEstimate;
  final double realisticEstimate;
  final double stretchEstimate;
  final int splitCount;
  final String? note;

  /// What this person actually pays.
  double get yourShare => realisticEstimate / (splitCount < 1 ? 1 : splitCount);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'lowEstimate': lowEstimate,
        'realisticEstimate': realisticEstimate,
        'stretchEstimate': stretchEstimate,
        'splitCount': splitCount,
        if (note != null) 'note': note,
      };

  factory SocialPlan.fromJson(Map<String, dynamic> j) => SocialPlan(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Plan',
        date: j['date'] as String? ?? '',
        lowEstimate: asDouble(j['lowEstimate']),
        realisticEstimate: asDouble(j['realisticEstimate']),
        stretchEstimate: asDouble(j['stretchEstimate']),
        splitCount: (j['splitCount'] as num?)?.toInt() ?? 1,
        note: j['note'] as String?,
      );
}

// ------------------------------------------------------- survival calculator

/// How comfortable the daily spendable figure is.
enum SurvivalZone { green, tight, critical }

extension SurvivalZoneLabel on SurvivalZone {
  String get label => switch (this) {
        SurvivalZone.green => 'Green Zone',
        SurvivalZone.tight => 'Tight Zone',
        SurvivalZone.critical => 'Critical Zone',
      };
}

class SurvivalResult {
  const SurvivalResult({
    required this.totalIncome,
    required this.fixedCostsTotal,
    required this.discretionaryPool,
    required this.dailySpendable,
    required this.zone,
  });

  final double totalIncome;
  final double fixedCostsTotal;
  final double discretionaryPool;
  final double dailySpendable;
  final SurvivalZone zone;
}

/// Projects income across [horizonDays] and works out what is safe per day.
///
/// Thresholds (25 / 12 USD per day) are taken from the web app.
SurvivalResult survival({
  required int horizonDays,
  required List<IncomeStream> streams,
  required List<FixedCost> fixedCosts,
  required double upcomingBills,
  required double balance,
  required double incomeToDate,
  required double spentToday,
}) {
  final days = horizonDays < 1 ? 1 : horizonDays;

  var totalIncome = 0.0;
  for (final s in streams) {
    totalIncome += switch (s.cadence) {
      IncomeCadence.oneTime => s.amount,
      IncomeCadence.weekly => s.amount * days / 7,
      IncomeCadence.monthly => s.amount * days / 30,
    };
  }

  final fixedTotal = fixedCosts.fold(0.0, (sum, c) => sum + c.amount);
  final pool = balance +
      incomeToDate -
      spentToday +
      totalIncome -
      fixedTotal -
      (upcomingBills < 0 ? 0 : upcomingBills);
  final perDay = pool / days;

  final zone = perDay >= 25
      ? SurvivalZone.green
      : perDay >= 12
          ? SurvivalZone.tight
          : SurvivalZone.critical;

  return SurvivalResult(
    totalIncome: totalIncome,
    fixedCostsTotal: fixedTotal,
    discretionaryPool: pool,
    dailySpendable: perDay,
    zone: zone,
  );
}

/// Daily spendable after committing to every realistic social plan.
double dailyAfterSocial({
  required double discretionaryPool,
  required List<SocialPlan> plans,
  required int horizonDays,
}) {
  final days = horizonDays < 1 ? 1 : horizonDays;
  final committed = plans.fold(0.0, (sum, p) => sum + p.yourShare);
  return (discretionaryPool - committed) / days;
}

// ------------------------------------------------------------- loan runway

class RunwayResult {
  const RunwayResult({
    required this.semesterExpenses,
    required this.weeksElapsed,
    required this.weeksRemaining,
    required this.burnRatePerWeek,
    required this.loanRemaining,
    required this.runwayWeeks,
    required this.recommendedWeeklyCap,
  });

  final double semesterExpenses;
  final double weeksElapsed;
  final double weeksRemaining;
  final double burnRatePerWeek;
  final double loanRemaining;
  final double runwayWeeks;
  final double recommendedWeeklyCap;

  /// 0..1 — how far the runway stretches across the remaining semester.
  double get progress =>
      weeksRemaining <= 0 ? 0 : (runwayWeeks / weeksRemaining).clamp(0.0, 1.0);

  /// True when the money runs out before term ends.
  bool get willRunOut => runwayWeeks < weeksRemaining;
}

/// Semester window: 16 weeks from 15 January of the current year.
({DateTime start, DateTime end}) semesterWindow({DateTime? now}) {
  final today = now ?? DateTime.now();
  final start = DateTime(today.year, 1, 15);
  return (start: start, end: start.add(const Duration(days: 16 * 7)));
}

/// Works out how long a lump sum lasts at the current burn rate.
RunwayResult loanRunway({
  required double lumpSum,
  required double safetyBuffer,
  required List<FinanceTransaction> transactions,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final window = semesterWindow(now: today);

  final expenses = transactions.where((t) {
    if (!t.isExpense) return false;
    final d = t.parsedDate;
    return d != null && !d.isBefore(window.start) && !d.isAfter(window.end);
  }).fold(0.0, (sum, t) => sum + t.amount);

  final elapsedDays = today.difference(window.start).inDays;
  final weeksElapsed = (elapsedDays < 7 ? 7 : elapsedDays) / 7;

  final remainingDays = window.end.difference(today).inDays;
  final weeksRemaining = (remainingDays < 7 ? 7 : remainingDays) / 7;

  final burn = expenses / weeksElapsed;
  final remaining = () {
    final r = lumpSum - expenses - safetyBuffer;
    return r < 0 ? 0.0 : r;
  }();

  final runway = burn <= 0 ? weeksRemaining : remaining / burn;

  return RunwayResult(
    semesterExpenses: expenses,
    weeksElapsed: weeksElapsed,
    weeksRemaining: weeksRemaining,
    burnRatePerWeek: burn,
    loanRemaining: remaining,
    runwayWeeks: runway,
    recommendedWeeklyCap: remaining / weeksRemaining,
  );
}

// ----------------------------------------------------------------- streaks

/// Counts consecutive on-track days ending today or yesterday.
///
/// The web app compared against a cursor carrying the current time-of-day and
/// kept iterating past a gap, which could over-count. This stops at the first
/// break, and tolerates the streak ending yesterday so it doesn't appear to
/// reset before you have logged today.
int currentStreak(List<String> isoDates, {DateTime? now}) {
  if (isoDates.isEmpty) return 0;

  final today = now ?? DateTime.now();
  final days = isoDates
      .map(DateTime.tryParse)
      .whereType<DateTime>()
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;

  var cursor = DateTime(today.year, today.month, today.day);
  if (days.first.isBefore(cursor)) {
    // Allow the streak to have ended yesterday.
    final yesterday = cursor.subtract(const Duration(days: 1));
    if (days.first.isBefore(yesterday)) return 0;
    cursor = yesterday;
  }

  var streak = 0;
  for (final day in days) {
    if (day == cursor) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    } else if (day.isBefore(cursor)) {
      break;
    }
  }
  return streak;
}
