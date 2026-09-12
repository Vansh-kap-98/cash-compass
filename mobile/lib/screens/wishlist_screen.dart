import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/widgets/app_card.dart';
import '../l10n/l10n.dart';
import '../models/wishlist_item.dart';
import '../state/currency_provider.dart';
import '../state/wishlist_provider.dart';
import 'sheet_scaffold.dart';

/// Items the user is holding off on buying — the "Wishlist Trick" literacy
/// card made concrete. Skipping an item at least 48 hours after adding it
/// feeds the Zero Impulse badge (`lib/logic/badges.dart`).
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WishlistScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = context.watch<WishlistProvider>().items;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wishlistScreenTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _AddWishlistItemSheet.show(context),
        child: const Icon(Icons.add),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.wishlistEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _WishlistTile(item: item),
                  ),
              ],
            ),
    );
  }
}

class _WishlistTile extends StatelessWidget {
  const _WishlistTile({required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                Text(
                  currency.formatFromUsd(item.amount),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (item.status == WishlistStatus.pending) ...[
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: l10n.wishlistMarkPurchased,
              onPressed: () =>
                  context.read<WishlistProvider>().markPurchased(item.id),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.wishlistMarkSkipped,
              onPressed: () =>
                  context.read<WishlistProvider>().markSkipped(item.id),
            ),
          ] else
            Text(
              item.status == WishlistStatus.purchased
                  ? l10n.wishlistStatusPurchased
                  : l10n.wishlistStatusSkipped,
              style: theme.textTheme.labelSmall,
            ),
        ],
      ),
    );
  }
}

class _AddWishlistItemSheet extends StatefulWidget {
  const _AddWishlistItemSheet();

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const _AddWishlistItemSheet(),
      );

  @override
  State<_AddWishlistItemSheet> createState() => _AddWishlistItemSheetState();
}

class _AddWishlistItemSheetState extends State<_AddWishlistItemSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final l10n = context.l10n;
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (name.isEmpty || amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _error = l10n.wishlistInvalid);
      return;
    }

    final currency = context.read<CurrencyProvider>();
    context.read<WishlistProvider>().addItem(
          name: name,
          amount: currency.convertToUsd(amount),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currency = context.watch<CurrencyProvider>();

    return SheetScaffold(
      title: l10n.wishlistAddItem,
      onSubmit: _save,
      submitLabel: l10n.wishlistAddItem,
      children: [
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.wishlistFieldName),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.wishlistFieldAmount(currency.currency.code),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
