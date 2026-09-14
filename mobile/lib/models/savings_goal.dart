import '../app/widgets/goal_icon.dart';
import 'json_utils.dart';

/// A savings target. [current] and [target] are both in USD.
class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.current,
    required this.target,
    required this.icon,
    this.targetDate,
    this.completedAt,
    this.giftFor,
  });

  final String id;
  final String name;
  final double current;
  final double target;
  final String icon;

  /// ISO calendar date (`yyyy-MM-dd`), set from the timeframe chosen when the
  /// goal was created. Null for goals created before this field existed.
  ///
  /// Used only by the Speed Demon badge (`lib/logic/badges.dart`) to tell
  /// whether a goal was completed ahead of schedule — nothing else reads it.
  final String? targetDate;

  /// ISO-8601 timestamp of the moment [current] first reached [target].
  /// Stamped once by `FinanceProvider.contributeToGoal` and never cleared, so
  /// a later contribution (there is no withdrawal) cannot erase it.
  final String? completedAt;

  /// Optional recipient or occasion for a gift goal (e.g. "Mom", "Family's Wedding").
  /// Null for non-gift personal goals.
  final String? giftFor;

  /// True when this goal is designated as a gift for a friend or family member.
  bool get isGift => giftFor != null && giftFor!.trim().isNotEmpty;

  /// Completion in the range 0..1. Guards against a zero or negative target.
  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();

  bool get isComplete => current >= target;

  SavingsGoal copyWith({
    double? current,
    String? completedAt,
    String? giftFor,
  }) =>
      SavingsGoal(
        id: id,
        name: name,
        current: current ?? this.current,
        target: target,
        icon: icon,
        targetDate: targetDate,
        completedAt: completedAt ?? this.completedAt,
        giftFor: giftFor ?? this.giftFor,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'current': current,
        'target': target,
        'icon': icon,
        if (targetDate != null) 'targetDate': targetDate,
        if (completedAt != null) 'completedAt': completedAt,
        if (giftFor != null) 'giftFor': giftFor,
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Goal',
        current: asDouble(j['current']),
        // Target is clamped to at least 1 on write; mirror that on read so a
        // corrupt zero can never produce a divide-by-zero in [progress].
        target: asDouble(j['target'], fallback: 1),
        icon: j['icon'] as String? ?? defaultGoalIconKey,
        targetDate: j['targetDate'] as String?,
        completedAt: j['completedAt'] as String?,
        giftFor: j['giftFor'] as String?,
      );
}
