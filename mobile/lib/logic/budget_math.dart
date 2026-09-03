/// Pure budget calculations, ported from `DashboardPlanner.tsx`.
///
/// Deliberately free of Flutter imports so it can be unit-tested without a
/// widget harness. Every formula and constant here is transcribed from the
/// React source — see `PARITY_SPEC.md` §3.
library;

import '../models/transaction.dart';

/// The everyday purchases each profile is priced against.
///
/// An enum rather than a name so the card can be read in any language; the
/// display name comes from `lib/l10n/presenters.dart`.
enum StapleKind { lunch, transit, groceries }

/// A cost-of-living profile used by the Location Budget Guidance card.
///
/// [key] is both the persisted value and the identifier the presenter maps to
/// a localised name — it must stay stable, so it is never shown to the user.
class GeoProfile {
  const GeoProfile({
    required this.key,
    required this.multiplier,
    required this.staples,
  });

  final String key;
  final double multiplier;
  final List<GeoStaple> staples;
}

class GeoStaple {
  const GeoStaple(this.kind, this.baseCost);
  final StapleKind kind;
  final double baseCost;
}

/// The three profiles, verbatim from the web app.
const List<GeoProfile> geoProfiles = [
  GeoProfile(
    key: 'us-city',
    multiplier: 1,
    staples: [
      GeoStaple(StapleKind.lunch, 16),
      GeoStaple(StapleKind.transit, 9),
      GeoStaple(StapleKind.groceries, 22),
    ],
  ),
  GeoProfile(
    key: 'india-metro',
    multiplier: 0.48,
    staples: [
      GeoStaple(StapleKind.lunch, 6),
      GeoStaple(StapleKind.transit, 2.5),
      GeoStaple(StapleKind.groceries, 10),
    ],
  ),
  GeoProfile(
    key: 'eastern-europe',
    multiplier: 0.72,
    staples: [
      GeoStaple(StapleKind.lunch, 11),
      GeoStaple(StapleKind.transit, 4.5),
      GeoStaple(StapleKind.groceries, 15),
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
///
/// The badge wording is derived from [affordable] by the presenter rather than
/// stored here, so this stays free of display strings.
class StapleVerdict {
  const StapleVerdict({
    required this.kind,
    required this.cost,
    required this.healthyLimit,
    required this.affordable,
  });

  final StapleKind kind;
  final double cost;
  final double healthyLimit;
  final bool affordable;
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
        kind: s.kind,
        cost: s.baseCost * profile.multiplier,
        healthyLimit: healthyLimit,
        affordable: s.baseCost * profile.multiplier <= healthyLimit,
      ),
  ];
}

/// Which of the rule-based daily tips applies.
///
/// The card renders these through `lib/l10n/presenters.dart`; this layer only
/// decides which fire, and in what order.
enum DailyTip {
  /// Already past the day's allowance.
  overBudget,

  /// Under 25% of the allowance left.
  finalQuarter,

  /// Comfortable headroom remaining.
  comfortable,

  /// Planned spending alone exceeds the allowance.
  plannedOverBudget,

  /// The running daily average exceeds the allowance.
  averageOverBudget,

  /// Filler, so the card always has three lines.
  categoryCaps,
}

/// Rule-based tips for the selected day, capped at three.
///
/// Exactly one of the first three fires, then the conditional ones, then a
/// filler if fewer than three have been produced.
List<DailyTip> dailySuggestions({
  required double selectedDayRemaining,
  required double selectedDayPlanned,
  required double dailyBudget,
  required double averagePerDay,
}) {
  final tips = <DailyTip>[];

  if (selectedDayRemaining < 0) {
    tips.add(DailyTip.overBudget);
  } else if (selectedDayRemaining < dailyBudget * 0.25) {
    tips.add(DailyTip.finalQuarter);
  } else {
    tips.add(DailyTip.comfortable);
  }

  if (selectedDayPlanned > dailyBudget) {
    tips.add(DailyTip.plannedOverBudget);
  }

  if (averagePerDay > dailyBudget) {
    tips.add(DailyTip.averageOverBudget);
  }

  if (tips.length < 3) {
    tips.add(DailyTip.categoryCaps);
  }

  return tips.take(3).toList();
}
