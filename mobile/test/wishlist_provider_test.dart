import 'package:cash_compass/models/wishlist_item.dart';
import 'package:cash_compass/state/wishlist_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget/harness.dart';

void main() {
  test('adding an item persists and reloads', () async {
    final prefs = FakePrefs();
    final first = WishlistProvider(prefs);
    await first.load();

    first.addItem(name: 'Shoes', amount: 60);
    expect(first.items, hasLength(1));
    expect(first.items.first.status, WishlistStatus.pending);
    await first.flush();

    final second = WishlistProvider(prefs);
    await second.load();
    expect(second.items, hasLength(1));
    expect(second.items.first.name, 'Shoes');
  });

  test('an invalid item is silently ignored', () async {
    final provider = WishlistProvider(FakePrefs());
    await provider.load();

    provider.addItem(name: '  ', amount: 60);
    provider.addItem(name: 'Shoes', amount: 0);
    provider.addItem(name: 'Shoes', amount: -5);

    expect(provider.items, isEmpty);
  });

  test('marking purchased or skipped resolves exactly once', () async {
    final provider = WishlistProvider(FakePrefs());
    await provider.load();
    provider.addItem(name: 'Shoes', amount: 60);
    final id = provider.items.first.id;

    provider.markSkipped(id);
    expect(provider.items.first.status, WishlistStatus.skipped);
    expect(provider.items.first.resolvedAt, isNotNull);

    // Already resolved — a second call must not flip it back to purchased.
    provider.markPurchased(id);
    expect(provider.items.first.status, WishlistStatus.skipped);
  });
}
