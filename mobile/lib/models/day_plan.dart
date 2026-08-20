import 'json_utils.dart';

/// A planned expense for a specific day. [estimate] is in USD.
class DayPlan {
  const DayPlan({
    required this.id,
    required this.title,
    required this.estimate,
    required this.date,
  });

  final String id;
  final String title;
  final double estimate;

  /// ISO calendar date, `yyyy-MM-dd`.
  final String date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'estimate': estimate,
        'date': date,
      };

  factory DayPlan.fromJson(Map<String, dynamic> j) => DayPlan(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Plan',
        estimate: asDouble(j['estimate']),
        date: j['date'] as String,
      );
}
