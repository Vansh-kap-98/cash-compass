import 'package:cash_compass/models/transaction.dart';
import 'package:cash_compass/services/prefs.dart';
import 'package:cash_compass/state/finance_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts writes instead of touching disk, so we can assert on how often the
/// store actually persists.
class CountingPrefs implements Prefs {
  int writes = 0;
  int removes = 0;
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
  Future<void> remove(String key) async {
    removes++;
    store.remove(key);
  }

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
      await remove(k);
    }
  }
}

void main() {
  void addOne(FinanceProvider f, int i) {
    f.addTransaction(
      name: 'Entry $i',
      amount: 10,
      type: TransactionType.expense,
      category: 'Food',
      date: todayIso(),
    );
  }

  test('a burst of edits collapses into a single write', () async {
    final prefs = CountingPrefs();
    final finance = FinanceProvider(prefs);

    for (var i = 0; i < 50; i++) {
      addOne(finance, i);
    }

    // Nothing has hit disk yet — the debounce window is still open.
    expect(prefs.writes, 0, reason: 'writes should be deferred, not immediate');

    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(finance.transactions.length, 50);
    expect(
      prefs.writes,
      1,
      reason: '50 mutations should coalesce into one write, not 50',
    );
  });

  test('flush persists pending edits immediately', () async {
    final prefs = CountingPrefs();
    final finance = FinanceProvider(prefs);

    addOne(finance, 1);
    expect(prefs.writes, 0);

    // This is what the app-lifecycle observer does when Android backgrounds us.
    await finance.flush();

    expect(prefs.writes, 1);
    final saved = prefs.store[PrefsKeys.finance] as Map<String, dynamic>;
    expect((saved['transactions'] as List).length, 1);
  });

  test('flush is a no-op when nothing is dirty', () async {
    final prefs = CountingPrefs();
    final finance = FinanceProvider(prefs);

    await finance.flush();
    expect(prefs.writes, 0);

    addOne(finance, 1);
    await finance.flush();
    await finance.flush();
    expect(prefs.writes, 1, reason: 'second flush had nothing pending');
  });

  test('resetAll cancels a pending write so data cannot resurrect', () async {
    final prefs = CountingPrefs();
    final finance = FinanceProvider(prefs);

    addOne(finance, 1);
    await finance.resetAll();

    // Wait past the debounce window the pending write was scheduled in.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(finance.transactions, isEmpty);
    expect(prefs.writes, 0,
        reason: 'the stale write must not fire after reset');
    expect(prefs.removes, 1);
  });

  group('derived values are memoised', () {
    test('repeat reads reuse the result until the data changes', () async {
      final finance = FinanceProvider(CountingPrefs());
      addOne(finance, 1);

      // Same revision -> identical instance, so cards reading the same derived
      // value in one frame do the work once.
      final first = finance.subscriptions;
      expect(identical(finance.subscriptions, first), isTrue);
      expect(identical(finance.dailyRecordsByDay, finance.dailyRecordsByDay),
          isTrue);

      addOne(finance, 2);

      expect(
        identical(finance.subscriptions, first),
        isFalse,
        reason: 'a mutation must invalidate the memo',
      );

      await finance.flush();
    });

    test('memoised aggregates match a fresh computation', () async {
      final finance = FinanceProvider(CountingPrefs());
      for (var i = 0; i < 5; i++) {
        addOne(finance, i);
      }

      expect(finance.dailyRecordsByDay.length, 1);
      expect(finance.averagePerDay, 50); // five 10s on one day
      expect(finance.subscriptions, isEmpty);
      expect(finance.behaviorPattern, isNull);
      expect(finance.suggestions, isNotEmpty);

      await finance.flush();
    });
  });

  test('aggregates stay correct after mutations', () async {
    final prefs = CountingPrefs();
    final finance = FinanceProvider(prefs);

    finance.addTransaction(
      name: 'Salary',
      amount: 1000,
      type: TransactionType.income,
      category: 'Salary',
      date: todayIso(),
    );
    addOne(finance, 1); // 10 expense today
    addOne(finance, 2); // 10 expense today

    expect(finance.totalIncome, 1000);
    expect(finance.totalSpent, 20);
    expect(finance.spentToday, 20);

    final byCategory = finance.expensesByCategory();
    expect(byCategory.first.key, 'Food');
    expect(byCategory.first.value, 20);

    await finance.flush();
  });
}
