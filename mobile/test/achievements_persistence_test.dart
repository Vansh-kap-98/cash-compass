import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/services/prefs.dart';
import 'package:cash_compass/state/achievements_provider.dart';
import 'package:cash_compass/state/finance_provider.dart';
import 'package:cash_compass/state/literacy_cards_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [Prefs] that also counts writes, so persistence tests can assert
/// on how often a store actually hits "disk" — same shape as
/// `persistence_debounce_test.dart`'s `CountingPrefs`, kept local here rather
/// than shared across test files.
class _CountingPrefs implements Prefs {
  int writes = 0;
  final Map<String, Object?> store = {};

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    writes++;
    store[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      store[key] as Map<String, dynamic>?;

  @override
  Future<void> remove(String key) async => store.remove(key);

  @override
  Future<String?> getString(String key) async => store[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    writes++;
    store[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => store[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    writes++;
    store[key] = value;
  }

  @override
  Future<List<dynamic>?> getJsonList(String key) async =>
      store[key] as List<dynamic>?;

  @override
  Future<void> setJsonList(String key, List<dynamic> value) async {
    writes++;
    store[key] = value;
  }

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final k in keys) {
      store.remove(k);
    }
  }
}

void main() {
  group('LiteracyCardsProvider', () {
    test('marking a card read persists and reloads', () async {
      final prefs = _CountingPrefs();
      final first = LiteracyCardsProvider(prefs);
      await first.load();
      first.markRead('daily-drip');
      await first.flush();

      final second = LiteracyCardsProvider(prefs);
      await second.load();
      expect(second.readCardIds, contains('daily-drip'));
    });

    test('marking the same card twice does not schedule a second write',
        () async {
      final prefs = _CountingPrefs();
      final cards = LiteracyCardsProvider(prefs);
      await cards.load();

      cards.markRead('daily-drip');
      await cards.flush();
      expect(prefs.writes, 1);

      cards.markRead('daily-drip');
      await cards.flush();
      expect(prefs.writes, 1, reason: 'already-read card must not rewrite');
    });
  });

  group('AchievementsProvider', () {
    test('recompute unlocks Category Boss and persists it', () async {
      final prefs = _CountingPrefs();
      final achievements = AchievementsProvider(prefs);
      await achievements.load();
      final finance = FinanceProvider(prefs);
      await finance.load();

      for (var i = 0; i < 5; i++) {
        finance.upsertBudget('Cat$i', 100);
      }

      achievements.recompute(finance: finance, readLiteracyCardCount: 0);
      expect(achievements.unlockedBadgeIds, contains('category-boss'));
      expect(achievements.consumeNewlyUnlocked(), contains('category-boss'));
      // Draining clears it — the same unlock does not celebrate twice.
      expect(achievements.consumeNewlyUnlocked(), isEmpty);

      await achievements.flush();
      final reloaded = AchievementsProvider(prefs);
      await reloaded.load();
      expect(reloaded.unlockedBadgeIds, contains('category-boss'));
    });

    test(
        'a badge already unlocked stays unlocked even if its condition regresses',
        () async {
      final prefs = _CountingPrefs();
      final achievements = AchievementsProvider(prefs);
      await achievements.load();
      final finance = FinanceProvider(prefs);
      await finance.load();

      finance.addGoal(name: 'Buffer', target: 500, initialAmount: 500);
      achievements.recompute(finance: finance, readLiteracyCardCount: 0);
      expect(achievements.unlockedBadgeIds, contains('goal-crusher'));

      // No un-complete path exists in the real app, but the provider itself
      // must not re-lock on a stale re-evaluation either way.
      finance.replaceAll(goals: const [
        SavingsGoal(
            id: 'g-new', name: 'Other', current: 0, target: 100, icon: '🎯'),
      ]);
      achievements.recompute(finance: finance, readLiteracyCardCount: 0);
      expect(achievements.unlockedBadgeIds, contains('goal-crusher'));
    });
  });
}
