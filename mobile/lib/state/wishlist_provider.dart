import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dev/log.dart';
import '../models/json_utils.dart';
import '../models/wishlist_item.dart';
import '../services/prefs.dart';

/// Items the user is holding off on buying. Same persistence shape as
/// `FinanceProvider`: hydrate once at startup, debounce writes.
class WishlistProvider extends ChangeNotifier {
  WishlistProvider(this._prefs);

  final Prefs _prefs;

  List<WishlistItem> items = [];
  bool loaded = false;

  Future<void> load() async {
    final raw = await _prefs.getJsonList(PrefsKeys.wishlist);
    if (raw != null) {
      items = decodeList(raw, WishlistItem.fromJson);
    }
    loaded = true;
    notifyListeners();
  }

  void addItem({required String name, required double amount}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !amount.isFinite || amount <= 0) return;

    items.insert(
      0,
      WishlistItem(
        id: 'wish-${DateTime.now().millisecondsSinceEpoch}',
        name: trimmed,
        amount: amount,
        addedAt: DateTime.now().toIso8601String(),
      ),
    );
    _persist();
  }

  void markPurchased(String id) => _resolve(id, WishlistStatus.purchased);

  void markSkipped(String id) => _resolve(id, WishlistStatus.skipped);

  void _resolve(String id, WishlistStatus status) {
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0 || items[index].status != WishlistStatus.pending) return;

    items[index] =
        items[index].resolve(status, DateTime.now().toIso8601String());
    _persist();
  }

  void _persist() {
    notifyListeners();
    _scheduleWrite();
  }

  Timer? _writeTimer;
  bool _writePending = false;
  static const _writeDebounce = Duration(milliseconds: 500);

  void _scheduleWrite() {
    _writePending = true;
    _writeTimer?.cancel();
    _writeTimer = Timer(_writeDebounce, flush);
  }

  Future<void> flush() async {
    if (!_writePending) return;
    _writeTimer?.cancel();
    _writePending = false;
    try {
      await _prefs.setJsonList(
        PrefsKeys.wishlist,
        items.map((i) => i.toJson()).toList(),
      );
    } catch (error) {
      logError('Wishlist write', error);
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
