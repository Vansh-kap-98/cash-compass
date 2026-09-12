import 'json_utils.dart';

/// Where one wishlist item stands. A pending item resolves to exactly one of
/// the other two and never moves again.
enum WishlistStatus { pending, purchased, skipped }

/// An item the user is holding off on buying, per the "Wishlist Trick"
/// literacy card: wait 30 days before buying to cut impulse spending.
///
/// [amount] is in USD, matching every other stored figure in the app.
class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.name,
    required this.amount,
    required this.addedAt,
    this.status = WishlistStatus.pending,
    this.resolvedAt,
  });

  final String id;
  final String name;
  final double amount;

  /// ISO-8601 timestamp of when the item was added.
  final String addedAt;

  final WishlistStatus status;

  /// ISO-8601 timestamp of when [status] left `pending`. Null while pending.
  ///
  /// Used only by the Zero Impulse badge (`lib/logic/badges.dart`), which
  /// needs the gap between [addedAt] and this to be at least 48 hours.
  final String? resolvedAt;

  WishlistItem resolve(WishlistStatus newStatus, String at) => WishlistItem(
        id: id,
        name: name,
        amount: amount,
        addedAt: addedAt,
        status: newStatus,
        resolvedAt: at,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'addedAt': addedAt,
        'status': status.name,
        if (resolvedAt != null) 'resolvedAt': resolvedAt,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> j) => WishlistItem(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        amount: asDouble(j['amount']),
        addedAt: j['addedAt'] as String,
        status: enumByName(WishlistStatus.values, j['status'], WishlistStatus.pending),
        resolvedAt: j['resolvedAt'] as String?,
      );
}
