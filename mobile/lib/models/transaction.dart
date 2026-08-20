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

/// Selectable expense categories, in the order the web app lists them.
const List<String> expenseCategories = [
  'Housing',
  'Groceries',
  'Transport',
  'Entertainment',
  'Food',
  'Utilities',
  'Shopping',
  'Health',
  'Travel',
  'Education',
  'Other',
];

/// Selectable income categories, in the order the web app lists them.
const List<String> incomeCategories = [
  'Salary',
  'Freelance',
  'Investment',
  'Business',
  'Gift',
  'Other',
];

/// How often an entry repeats.
///
/// There is no scheduler behind this — matching the web app, the choice is
/// appended to the note as `Recurring: <value>` and used only by the
/// subscription detector. A real scheduler would need notifications and
/// background work, which is out of scope.
enum Recurrence { none, daily, weekly, biweekly, monthly, yearly }

extension RecurrenceLabel on Recurrence {
  String get label => switch (this) {
        Recurrence.none => 'One-time',
        Recurrence.daily => 'Daily',
        Recurrence.weekly => 'Weekly',
        Recurrence.biweekly => 'Biweekly',
        Recurrence.monthly => 'Monthly',
        Recurrence.yearly => 'Yearly',
      };
}

extension ReasonTagLabel on ReasonTag {
  String get label => switch (this) {
        ReasonTag.emotional => 'Emotional purchase',
        ReasonTag.social => 'Social',
        ReasonTag.discount => 'Discount / sale',
        ReasonTag.impulse => 'Impulse',
      };
}

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

  /// [date] parsed to a [DateTime], or null if it is unparseable.
  ///
  /// Not cached — the class is `const`, so it cannot hold a mutable field.
  /// Prefer the string helpers below where they suffice: `date` is ISO
  /// `yyyy-MM-dd`, which compares and sorts correctly as plain text, and
  /// skipping the parse is significantly faster across a long list.
  DateTime? get parsedDate => DateTime.tryParse(date);

  /// True when this entry falls in the given `yyyy-MM` month.
  ///
  /// A prefix test rather than a parse-and-compare: the month rules walk every
  /// transaction, and `DateTime.tryParse` dominated that pass.
  bool isInMonthPrefix(String yearMonth) => date.startsWith(yearMonth);

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
