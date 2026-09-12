import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../logic/literacy_cards.dart';
import '../state/literacy_cards_provider.dart';

/// Browsable list of every financial literacy card, grouped by category.
///
/// Opening a card marks it read, which is what the Financial Master badge
/// counts (`lib/logic/badges.dart`).
class FinancialTipsScreen extends StatelessWidget {
  const FinancialTipsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FinancialTipsScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final readIds = context.watch<LiteracyCardsProvider>().readCardIds;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.financialTipsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (final category in LiteracyCategory.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                literacyCategoryLabel(l10n, category),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final card in literacyCards
                .where((c) => c.category == category))
              _CardTile(card: card, isRead: readIds.contains(card.id)),
          ],
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.isRead});

  final LiteracyCard card;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isRead ? Icons.check_circle : Icons.circle_outlined,
          color: isRead ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(literacyCardTitle(l10n, card.id)),
        onTap: () => _openCard(context),
      ),
    );
  }

  Future<void> _openCard(BuildContext context) async {
    final l10n = context.l10n;
    context.read<LiteracyCardsProvider>().markRead(card.id);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(literacyCardTitle(l10n, card.id)),
        content: SingleChildScrollView(
          child: Text(literacyCardBody(l10n, card.id)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.actionDone),
          ),
        ],
      ),
    );
  }
}
