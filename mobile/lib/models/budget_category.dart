import 'json_utils.dart';

/// A monthly spending limit for one category. [monthlyLimit] is in USD.
///
/// Nothing in the web UI currently creates these — `upsertBudget` has no caller.
/// The type is kept because the persisted JSON shape carries a `budgets` array
/// and the insight rules read it, so dropping it would break round-tripping.
class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    required this.monthlyLimit,
  });

  final String id;
  final String name;
  final double monthlyLimit;

  BudgetCategory copyWith({double? monthlyLimit}) => BudgetCategory(
        id: id,
        name: name,
        monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'monthlyLimit': monthlyLimit,
      };

  factory BudgetCategory.fromJson(Map<String, dynamic> j) => BudgetCategory(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Category',
        monthlyLimit: asDouble(j['monthlyLimit']),
      );
}
