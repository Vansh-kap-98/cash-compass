/// Pure budget calculations, ported from `DashboardPlanner.tsx`.
///
/// Deliberately free of Flutter imports so it can be unit-tested without a
/// widget harness. Every formula and constant here is transcribed from the
/// React source — see `PARITY_SPEC.md` §3.
library;

import '../models/transaction.dart';

/// A cost-of-living profile used by the Location Budget Guidance card.
class GeoProfile {
  const GeoProfile({
    required this.key,
    required this.label,
    required this.multiplier,
    required this.staples,
  });

  final String key;
  final String label;
  final double multiplier;
  final List<GeoStaple> staples;
}

class GeoStaple {
  const GeoStaple(this.name, this.baseCost);
  final String name;
  final double baseCost;
}

/// The three profiles, verbatim from the web app.
const List<GeoProfile> geoProfiles = [
  GeoProfile(
    key: 'us-city',
    label: 'US City',
    multiplier: 1,
    staples: [
      GeoStaple('Lunch', 16),
      GeoStaple('Transit', 9),
      GeoStaple('Groceries', 22),
    ],
  ),
  GeoProfile(
    key: 'india-metro',
    label: 'India Metro',
    multiplier: 0.48,
    staples: [
      GeoStaple('Lunch', 6),
      GeoStaple('Transit', 2.5),
      GeoStaple('Groceries', 10),
    ],
  ),
  GeoProfile(
    key: 'eastern-europe',
    label: 'Eastern Europe',
    multiplier: 0.72,
    staples: [
      GeoStaple('Lunch', 11),
      GeoStaple('Transit', 4.5),
      GeoStaple('Groceries', 15),
    ],
  ),
];

GeoProfile geoProfileFor(String key) => geoProfiles
    .firstWhere((p) => p.key == key, orElse: () => geoProfiles.first);

/// One day's total expense, used for the records list and the daily average.
class DailyRecord {
  const DailyRecord(this.date, this.expense);
  final String date;
  final double expense;
}

/// Groups expenses by calendar day, newest first.
List<DailyRecord> dailyRecords(List<FinanceTransaction> transactions) {
  final totals = <String, double>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    totals[t.date] = (totals[t.date] ?? 0) + t.amount;
  }
  final records = totals.entries
      .map((e) => DailyRecord(e.key, e.value))
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return records;
}

/// Mean spend across days that actually have spending.
///
/// Note this divides by the number of *recorded* days, not by elapsed days —
/// so days with no entries do not drag the average down. That matches the web
/// app, and it is the more forgiving reading.
double averageSpentPerDay(List<DailyRecord> records) {
  if (records.isEmpty) return 0;
  final total = records.fold(0.0, (sum, r) => sum + r.expense);
  return total / records.length;
}

/// Inclusive day count between two ISO dates, floored at 1.
int daysInRange(DateTime start, DateTime end) {
  final diff = end.difference(start).inDays + 1;
  return diff < 1 ? 1 : diff;
}

/// Days left in the month containing [now], counting today.
int daysRemainingInMonth(DateTime now) {
  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
  final remaining = daysInMonth - now.day + 1;
  return remaining < 1 ? 1 : remaining;
}

/// Spend allowance per day.
///
/// Uses the user's chosen date range when one is set, otherwise spreads the
/// remaining balance across the rest of the current month.
double dailyBudget({
  required double remainingBalance,
  DateTime? rangeStart,
  DateTime? rangeEnd,
  DateTime? now,
}) {
  if (remainingBalance <= 0) return 0;
  final today = now ?? DateTime.now();

  final days = (rangeStart != null && rangeEnd != null)
      ? daysInRange(rangeStart, rangeEnd)
      : daysRemainingInMonth(today);

  return remainingBalance / days;
}

/// Verdict for one staple item on the Location Guidance card.
class StapleVerdict {
  const StapleVerdict({
    required this.name,
    required this.cost,
    required this.healthyLimit,
    required this.affordable,
  });

  final String name;
  final double cost;
  final double healthyLimit;
  final bool affordable;

  String get badge => affordable ? 'On Budget' : 'Trim Needed';
}

/// Compares each staple against 40% of what is left for the selected day.
List<StapleVerdict> stapleVerdicts({
  required GeoProfile profile,
  required double selectedDayRemaining,
}) {
  final healthyLimit =
      selectedDayRemaining * 0.4 < 0 ? 0.0 : selectedDayRemaining * 0.4;
  return [
    for (final s in profile.staples)
      StapleVerdict(
        name: s.name,
        cost: s.baseCost * profile.multiplier,
        healthyLimit: healthyLimit,
        affordable: s.baseCost * profile.multiplier <= healthyLimit,
      ),
  ];
}

/// Rule-based tips for the selected day, capped at three.
///
/// Exactly one of the first three fires, then the conditional ones, then a
/// filler if fewer than three have been produced.
List<String> dailySuggestions({
  required double selectedDayRemaining,
  required double selectedDayPlanned,
  required double dailyBudget,
  required double averagePerDay,
}) {
  final tips = <String>[];

  if (selectedDayRemaining < 0) {
    tips.add(
      'You are over today\'s budget. Switch to essential-only purchases for '
      'the rest of the day.',
    );
  } else if (selectedDayRemaining < dailyBudget * 0.25) {
    tips.add(
      'You are in the final 25% of your daily budget. Keep only high-priority '
      'plan items.',
    );
  } else {
    tips.add(
      'You still have comfortable room today. Front-load essentials and delay '
      'impulse categories.',
    );
  }

  if (selectedDayPlanned > dailyBudget) {
    tips.add(
      'Your planned spend is above budget. Reduce one plan item by around '
      '20-30%.',
    );
  }

  if (averagePerDay > dailyBudget) {
    tips.add(
      'Your average daily spend is above your location-adjusted budget. Try a '
      'three-day low-spend streak.',
    );
  }

  if (tips.length < 3) {
    tips.add(
      'Use category caps for Food and Shopping today to protect tomorrow\'s '
      'flexibility.',
    );
  }

  return tips.take(3).toList();
}
