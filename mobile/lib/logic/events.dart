/// Regional financial calendar and event-window spend forecasting.
///
/// Port of `widgets/EventCalendar.tsx`. See `PARITY_SPEC.md` §6.
library;

import '../models/transaction.dart';


enum Region { india, russia }

extension RegionLabel on Region {
  String get label => this == Region.india ? 'India' : 'Russia';
  String get id => this == Region.india ? 'India' : 'Russia';

  static Region fromId(String? id) =>
      id == 'Russia' ? Region.russia : Region.india;
}

class FinancialEvent {
  const FinancialEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.end,
    required this.note,
  });

  final String id;
  final String name;
  final String type;
  final DateTime start;
  final DateTime end;
  final String note;
}

/// Builds a dated event, rolling it into next year once it is well past.
///
/// The 7-day grace window is deliberate: an event that finished a few days ago
/// stays visible rather than jumping eleven months into the future.
FinancialEvent _event({
  required String id,
  required String name,
  required String type,
  required int month,
  required int day,
  int durationDays = 0,
  required String note,
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
    name: name,
    type: type,
    start: start,
    end: start.add(Duration(days: durationDays)),
    note: note,
  );
}

/// The event list for a region, sorted by start date.
List<FinancialEvent> eventsFor(Region region, {DateTime? now}) {
  final events = region == Region.russia
      ? [
          _event(
            id: 'ru-winter',
            name: 'Winter exam season',
            type: 'Academic',
            month: 1,
            day: 10,
            durationDays: 18,
            note: 'Study materials, transport, and late-night food often rise.',
            now: now,
          ),
          _event(
            id: 'ru-new-year',
            name: 'New Year holidays',
            type: 'Holiday',
            month: 12,
            day: 29,
            durationDays: 9,
            note: 'Gifting, travel, and social spending cluster around this break.',
            now: now,
          ),
          _event(
            id: 'ru-stipend',
            name: 'Student stipend cycle',
            type: 'Income',
            month: 8,
            day: 5,
            note: 'A regular stipend date to anchor your monthly plan.',
            now: now,
          ),
        ]
      : [
          _event(
            id: 'in-exams',
            name: 'University exam window',
            type: 'Academic',
            month: 7,
            day: 18,
            durationDays: 8,
            note: 'Printing, travel, and convenience food can increase during '
                'exam weeks.',
            now: now,
          ),
          _event(
            id: 'in-diwali',
            name: 'Diwali cluster',
            type: 'Festival',
            month: 11,
            day: 7,
            durationDays: 5,
            note: 'Gifts, travel, and celebrations can put pressure on '
                'flexible cash.',
            now: now,
          ),
          _event(
            id: 'in-semester',
            name: 'Semester reset',
            type: 'Student costs',
            month: 8,
            day: 1,
            durationDays: 13,
            note: 'Books, supplies, and housing deposits often return at the '
                'start of term.',
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
