import 'dart:async';

import 'package:flutter/foundation.dart';

import '../dev/log.dart';
import '../services/prefs.dart';

/// Tracks which financial literacy cards have been opened to their full-screen
/// view. Same persistence shape as `FinanceProvider`: hydrate once at
/// startup, debounce writes.
class LiteracyCardsProvider extends ChangeNotifier {
  LiteracyCardsProvider(this._prefs);

  final Prefs _prefs;

  Set<String> readCardIds = {};
  bool loaded = false;

  Future<void> load() async {
    final raw = await _prefs.getJsonList(PrefsKeys.literacyCards);
    if (raw != null) {
      readCardIds = {for (final v in raw) v as String};
    }
    loaded = true;
    notifyListeners();
  }

  /// Marks a card as read. A no-op (no notify, no write) if it already was —
  /// re-opening a card you've seen before shouldn't churn a disk write.
  void markRead(String cardId) {
    if (!readCardIds.add(cardId)) return;
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
      await _prefs.setJsonList(PrefsKeys.literacyCards, readCardIds.toList());
    } catch (error) {
      logError('LiteracyCards write', error);
      _writePending = true;
    }
  }

  @override
  void dispose() {
    _writeTimer?.cancel();
    super.dispose();
  }
}
