import 'json_utils.dart';

enum TransactionType { income, expense }

/// Why an unplanned expense happened. Only ever recorded on expenses.
enum ReasonTag { emotional, social, discount, impulse }

/// Category -> emoji, ported from `categoryIcons` in `FinanceContext.tsx`.
const Map<String, String> categoryIcons = {
  'Income': '💰',
  'Salary': '🏦',
  'Freelance': '💼',
  'Groceries': '🛒',
  'Transport': '🚗',
  'Housing': '🏠',
  'Utilities': '💡',
  'Entertainment': '🎬',
  'Food': '🍽️',
  'Shopping': '🛍️',
  'Health': '🩺',
  'Travel': '✈️',
  'Education': '📚',
  'Savings': '🪙',
};

/// A single income or expense entry.
///
/// [amount] is always stored in USD, matching the web app: the active currency
/// is a display concern, converted at the edges.
class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.icon,
    this.createdAt,
    this.isUnplanned = false,
    this.reasonTags = const [],
  });

  final String id;
  final String name;

  /// Always USD.
  final double amount;
  final TransactionType type;
  final String category;

  /// ISO calendar date, `yyyy-MM-dd`.
  final String date;
  final String? note;
  final String? icon;

  /// ISO-8601 timestamp. The behaviour insights use the time component to tell
  /// night spending from day spending, so it must be preserved.
  final String? createdAt;
  final bool isUnplanned;
  final List<ReasonTag> reasonTags;

  bool get isExpense => type == TransactionType.expense;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date,
        if (note != null) 'note': note,
        if (icon != null) 'icon': icon,
        if (createdAt != null) 'createdAt': createdAt,
        'isUnplanned': isUnplanned,
        'reasonTags': reasonTags.map((t) => t.name).toList(),
      };

  factory FinanceTransaction.fromJson(Map<String, dynamic> j) {
    final rawName = (j['name'] as String?)?.trim() ?? '';
    return FinanceTransaction(
      id: j['id'] as String,
      name: rawName.isEmpty ? 'Manual Entry' : rawName,
      amount: asDouble(j['amount']),
      type: enumByName(
          TransactionType.values, j['type'], TransactionType.expense),
      category: j['category'] as String? ?? 'Other',
      date: j['date'] as String,
      note: j['note'] as String?,
      icon: j['icon'] as String?,
      createdAt: j['createdAt'] as String?,
      isUnplanned: j['isUnplanned'] as bool? ?? false,
      reasonTags: enumListByName(ReasonTag.values, j['reasonTags']),
    );
  }
}
