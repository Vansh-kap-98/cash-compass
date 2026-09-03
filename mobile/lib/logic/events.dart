/// Regional financial calendar and event-window spend forecasting.
///
/// Port of `widgets/EventCalendar.tsx`. See `PARITY_SPEC.md` §6.
library;

import '../models/transaction.dart';

enum Region { india, russia }

extension RegionLabel on Region {
  /// Persisted value, and the one the web app wrote. Never shown to the user —
  /// the display name is localised in `lib/l10n/presenters.dart`.
  String get id => this == Region.india ? 'India' : 'Russia';

  static Region fromId(String? id) =>
      id == 'Russia' ? Region.russia : Region.india;
}

/// Which calendar entry this is.
///
/// The name, category, and note attached to each are display strings and live
/// in the localisations; this enum is what the logic and the presenter agree on.
enum FinancialEventKind {
  winterExam,
  newYear,
  stipend,
  universityExam,
  diwali,
  semesterReset,
}

/// The broad category a [FinancialEventKind] falls into, shown beside its date.
enum FinancialEventType { academic, holiday, income, festival, studentCosts }

class FinancialEvent {
  const FinancialEvent({
    required this.id,
    required this.kind,
    required this.type,
    required this.start,
    required this.end,
  });

  final String id;
  final FinancialEventKind kind;
  final FinancialEventType type;
  final DateTime start;
  final DateTime end;
}

/// Builds a dated event, rolling it into next year once it is well past.
///
/// The 7-day grace window is deliberate: an event that finished a few days ago
/// stays visible rather than jumping eleven months into the future.
FinancialEvent _event({
  required String id,
  required FinancialEventKind kind,
  required FinancialEventType type,
  required int month,
  required int day,
  int durationDays = 0,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  var start = DateTime(today.year, month, day);
  final grace = DateTime(today.year, today.month, today.day - 7);
  if (start.isBefore(grace)) {
    start = DateTime(today.year + 1, month, day);
  }
  return FinancialEvent(
    id: id,
    kind: kind,
    type: type,
    start: start,
    end: start.add(Duration(days: durationDays)),
  );
}

/// The event list for a region, sorted by start date.
List<FinancialEvent> eventsFor(Region region, {DateTime? now}) {
  final events = region == Region.russia
      ? [
          _event(
            id: 'ru-winter',
            kind: FinancialEventKind.winterExam,
            type: FinancialEventType.academic,
            month: 1,
            day: 10,
            durationDays: 18,
            now: now,
          ),
          _event(
            id: 'ru-new-year',
            kind: FinancialEventKind.newYear,
            type: FinancialEventType.holiday,
            month: 12,
            day: 29,
            durationDays: 9,
            now: now,
          ),
          _event(
            id: 'ru-stipend',
            kind: FinancialEventKind.stipend,
            type: FinancialEventType.income,
            month: 8,
            day: 5,
            now: now,
          ),
        ]
      : [
          _event(
            id: 'in-exams',
            kind: FinancialEventKind.universityExam,
            type: FinancialEventType.academic,
            month: 7,
            day: 18,
            durationDays: 8,
            now: now,
          ),
          _event(
            id: 'in-diwali',
            kind: FinancialEventKind.diwali,
            type: FinancialEventType.festival,
            month: 11,
            day: 7,
            durationDays: 5,
            now: now,
          ),
          _event(
            id: 'in-semester',
            kind: FinancialEventKind.semesterReset,
            type: FinancialEventType.studentCosts,
            month: 8,
            day: 1,
            durationDays: 13,
            now: now,
          ),
        ];

  events.sort((a, b) => a.start.compareTo(b.start));
  return events;
}

/// Whole days from today until [date].
int daysUntil(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final a = DateTime(date.year, date.month, date.day);
  final b = DateTime(today.year, today.month, today.day);
  return a.difference(b).inDays;
}

/// The event within the next seven days, if any.
FinancialEvent? activeEvent(List<FinancialEvent> events, {DateTime? now}) {
  for (final e in events) {
    final d = daysUntil(e.start, now: now);
    if (d >= 0 && d <= 7) return e;
  }
  return null;
}

/// Projected spend during an upcoming event window.
class EventForecast {
  const EventForecast({
    required this.usual,
    required this.projected,
    required this.increase,
    required this.basedOnHistory,
  });

  final double usual;
  final double projected;
  final double increase;

  /// True when prior spending inside this window was found, which makes the
  /// projection meaningfully better than a flat uplift.
  final bool basedOnHistory;
}

/// Estimates spend for [event] from history.
///
/// Uses a year-agnostic month/day comparison so last year's Diwali informs this
/// year's. Applies a 16% uplift when prior window spending exists, 12% when
/// falling back to the overall average.
EventForecast forecastFor({
  required List<FinanceTransaction> transactions,
  FinancialEvent? event,
}) {
  final expenses = transactions.where((t) => t.isExpense).toList();
  final average = expenses.isEmpty
      ? 0.0
      : expenses.fold(0.0, (sum, t) => sum + t.amount) / expenses.length;

  if (event == null) {
    return EventForecast(
      usual: average,
      projected: average,
      increase: 0,
      basedOnHistory: false,
    );
  }

  int monthDay(DateTime d) => d.month * 31 + d.day;
  final startKey = monthDay(event.start) - 7;
  final endKey = monthDay(event.end);

  final window = expenses.where((t) {
    final d = t.parsedDate;
    if (d == null) return false;
    final key = monthDay(d);
    return key >= startKey && key <= endKey;
  }).toList();

  final historical = window.isEmpty
      ? average
      : window.fold(0.0, (sum, t) => sum + t.amount) / window.length;
  final projected = historical * (window.isEmpty ? 1.12 : 1.16);
  final increase = projected - historical;

  return EventForecast(
    usual: historical,
    projected: projected,
    increase: increase < 0 ? 0 : increase,
    basedOnHistory: window.isNotEmpty,
  );
}
