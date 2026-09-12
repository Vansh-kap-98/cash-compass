/// Static financial-tip content for the Financial Tips screen.
///
/// Pure data, no Flutter imports — display strings live in
/// [AppLocalizations] and are looked up by [LiteracyCard.id] via
/// `literacyCardTitle`/`literacyCardBody` in `l10n/presenters.dart`. Keeping
/// the English/Russian text out of this file means the same id list is used
/// by both languages and by [LiteracyCardsProvider]'s read-tracking, without
/// this file needing to change when wording does.
library;

/// The five fixed groupings cards are organised under.
enum LiteracyCategory {
  foodDelivery,
  subscriptionsTech,
  smartShopping,
  savingsPlanning,
  mindsetBudgeting,
}

/// One tip. Content-free by design — see the library doc.
class LiteracyCard {
  const LiteracyCard({required this.id, required this.category});

  /// Stable slug. Never reused or renumbered: it is the persisted
  /// read-tracking key in [LiteracyCardsProvider] and the l10n lookup key.
  final String id;
  final LiteracyCategory category;
}

/// All literacy cards, in display order within each category.
const List<LiteracyCard> literacyCards = [
  LiteracyCard(id: 'daily-drip', category: LiteracyCategory.foodDelivery),
  LiteracyCard(
    id: 'late-night-craving',
    category: LiteracyCategory.foodDelivery,
  ),
  LiteracyCard(
    id: 'meal-prep-power',
    category: LiteracyCategory.foodDelivery,
  ),
  LiteracyCard(id: 'hungry-shopper', category: LiteracyCategory.foodDelivery),
  LiteracyCard(
    id: 'ghost-subscriptions',
    category: LiteracyCategory.subscriptionsTech,
  ),
  LiteracyCard(
    id: 'student-discounts',
    category: LiteracyCategory.subscriptionsTech,
  ),
  LiteracyCard(
    id: 'upgrade-cycle',
    category: LiteracyCategory.subscriptionsTech,
  ),
  LiteracyCard(
    id: 'the-24-hour-rule',
    category: LiteracyCategory.smartShopping,
  ),
  LiteracyCard(
    id: 'off-season-steals',
    category: LiteracyCategory.smartShopping,
  ),
  LiteracyCard(id: 'textbook-hack', category: LiteracyCategory.smartShopping),
  LiteracyCard(id: 'micro-savings', category: LiteracyCategory.savingsPlanning),
  LiteracyCard(
    id: 'emergency-cushion',
    category: LiteracyCategory.savingsPlanning,
  ),
  LiteracyCard(
    id: 'compound-interest',
    category: LiteracyCategory.savingsPlanning,
  ),
  LiteracyCard(
    id: 'the-50-30-20-guide',
    category: LiteracyCategory.mindsetBudgeting,
  ),
  LiteracyCard(
    id: 'invisible-leaks',
    category: LiteracyCategory.mindsetBudgeting,
  ),
  LiteracyCard(id: 'the-hour-value', category: LiteracyCategory.mindsetBudgeting),
  LiteracyCard(id: 'credit-trap', category: LiteracyCategory.mindsetBudgeting),
  LiteracyCard(
    id: 'wishlist-trick',
    category: LiteracyCategory.mindsetBudgeting,
  ),
];
