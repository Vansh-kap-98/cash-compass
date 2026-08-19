import 'json_utils.dart';

/// A savings target. [current] and [target] are both in USD.
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.current,
    required this.target,
    required this.icon,
  });

  final String id;
  final String name;
  final double current;
  final double target;
  final String icon;

  /// Completion in the range 0..1. Guards against a zero or negative target.
  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();

  bool get isComplete => current >= target;

  SavingsGoal copyWith({double? current}) => SavingsGoal(
        id: id,
        name: name,
        current: current ?? this.current,
        target: target,
        icon: icon,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'current': current,
        'target': target,
        'icon': icon,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Goal',
        current: asDouble(j['current']),
        // Target is clamped to at least 1 on write; mirror that on read so a
        // corrupt zero can never produce a divide-by-zero in [progress].
        target: asDouble(j['target'], fallback: 1),
        icon: j['icon'] as String? ?? '🎯',
      );
}
