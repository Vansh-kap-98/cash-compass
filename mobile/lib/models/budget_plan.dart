import 'json_utils.dart';

/// What kind of thing is being budgeted for.
enum BudgetPlanType { trip, outing, event }

extension BudgetPlanTypeLabel on BudgetPlanType {
  String get label => switch (this) {
        BudgetPlanType.trip => 'Trip',
        BudgetPlanType.outing => 'Outing',
        BudgetPlanType.event => 'Event',
      };
}

/// One estimated cost inside a plan. [estimate] is in USD.
class BudgetLineItem {
  const BudgetLineItem({
    required this.id,
    required this.name,
    required this.estimate,
  });

  final String id;
  final String name;
  final double estimate;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'estimate': estimate};

  factory BudgetLineItem.fromJson(Map<String, dynamic> j) => BudgetLineItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Item',
        estimate: asDouble(j['estimate']),
      );
}

/// A finalised budget, or an in-progress draft.
///
/// Amounts are stored in USD. The web app stored raw display-currency values
/// here, which meant a plan budgeted in INR showed INR figures under a `$`
/// sign after switching currency — see `PARITY_SPEC.md` §0.
class BudgetPlan {
  const BudgetPlan({
    required this.id,
    required this.title,
    required this.planType,
    required this.dateFrom,
    this.dateTo,
    required this.people,
    required this.items,
    required this.createdAt,
    this.settledWith = const [],
  });

  final String id;
  final String title;
  final BudgetPlanType planType;
  final String dateFrom;
  final String? dateTo;

  /// Number of people splitting the cost, at least 1.
  final int people;
  final List<BudgetLineItem> items;
  final String createdAt;

  /// Names of participants already settled up, used by the roommate widget.
  final List<String> settledWith;

  double get total => items.fold(0.0, (sum, i) => sum + i.estimate);

  /// Each person's share. Derived rather than stored so it can never disagree
  /// with the item list.
  double get perPerson => total / (people < 1 ? 1 : people);

  /// What the others collectively owe the payer.
  double get owedToYou => perPerson * ((people < 1 ? 1 : people) - 1);

  BudgetPlan copyWith({
    String? title,
    BudgetPlanType? planType,
    String? dateFrom,
    String? dateTo,
    int? people,
    List<BudgetLineItem>? items,
    List<String>? settledWith,
  }) =>
      BudgetPlan(
        id: id,
        title: title ?? this.title,
        planType: planType ?? this.planType,
        dateFrom: dateFrom ?? this.dateFrom,
        dateTo: dateTo ?? this.dateTo,
        people: people ?? this.people,
        items: items ?? this.items,
        createdAt: createdAt,
        settledWith: settledWith ?? this.settledWith,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'planType': planType.name,
        'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
        'people': people,
        'items': items.map((i) => i.toJson()).toList(),
        // Written for compatibility with the web app's shape even though both
        // are derived on read.
        'total': total,
        'perPerson': perPerson,
        'createdAt': createdAt,
        'settledWith': settledWith,
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> j) => BudgetPlan(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Plan',
        planType: enumByName(
            BudgetPlanType.values, j['planType'], BudgetPlanType.trip),
        dateFrom: j['dateFrom'] as String? ?? '',
        dateTo: j['dateTo'] as String?,
        people: (j['people'] as num?)?.toInt() ?? 1,
        items: decodeList(j['items'], BudgetLineItem.fromJson),
        createdAt: j['createdAt'] as String? ?? '',
        settledWith: [
          for (final s in (j['settledWith'] as List? ?? const []))
            if (s is String) s,
        ],
      );
}
