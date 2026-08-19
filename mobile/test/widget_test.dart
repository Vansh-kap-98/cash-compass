import 'package:cash_compass/models/json_utils.dart';
import 'package:cash_compass/models/savings_goal.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('asDouble', () {
    test('reads ints, doubles, and numeric strings', () {
      // The core money hazard: jsonDecode returns int for 5 and double for 5.0.
      expect(asDouble(5), 5.0);
      expect(asDouble(5.5), 5.5);
      expect(asDouble('5.5'), 5.5);
      expect(asDouble(null), 0.0);
      expect(asDouble('not a number', fallback: 3), 3.0);
    });
  });

  group('asNullableDouble', () {
    test('rejects null and non-finite values', () {
      expect(asNullableDouble(null), isNull);
      expect(asNullableDouble(double.infinity), isNull);
      expect(asNullableDouble(double.nan), isNull);
      expect(asNullableDouble(12), 12.0);
    });
  });

  group('enum decoding', () {
    test('falls back instead of throwing on unknown names', () {
      expect(
        enumByName(TransactionType.values, 'income', TransactionType.expense),
        TransactionType.income,
      );
      expect(
        enumByName(TransactionType.values, 'bogus', TransactionType.expense),
        TransactionType.expense,
      );
    });

    test('drops unknown reason tags rather than failing the record', () {
      final tags = enumListByName(
        ReasonTag.values,
        ['impulse', 'from-the-future', 'social'],
      );
      expect(tags, [ReasonTag.impulse, ReasonTag.social]);
    });
  });

  group('FinanceTransaction', () {
    test('round-trips through JSON', () {
      const original = FinanceTransaction(
        id: 'tx-1',
        name: 'Coffee',
        amount: 4.5,
        type: TransactionType.expense,
        category: 'Food',
        date: '2026-08-19',
        note: 'Morning',
        icon: '🍽️',
        isUnplanned: true,
        reasonTags: [ReasonTag.impulse],
      );

      final decoded = FinanceTransaction.fromJson(original.toJson());

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.amount, original.amount);
      expect(decoded.type, original.type);
      expect(decoded.category, original.category);
      expect(decoded.date, original.date);
      expect(decoded.note, original.note);
      expect(decoded.isUnplanned, isTrue);
      expect(decoded.reasonTags, [ReasonTag.impulse]);
    });

    test('decodes a whole-number amount written as an int', () {
      // This is the case that crashes if amount is read with `as double`.
      final decoded = FinanceTransaction.fromJson({
        'id': 'tx-2',
        'name': 'Rent',
        'amount': 1200,
        'type': 'expense',
        'category': 'Housing',
        'date': '2026-08-01',
      });
      expect(decoded.amount, 1200.0);
    });
  });

  group('SavingsGoal', () {
    test('progress is clamped and safe against a zero target', () {
      const goal =
          SavingsGoal(id: 'g', name: 'Trip', current: 50, target: 100, icon: '🎯');
      expect(goal.progress, 0.5);

      const over =
          SavingsGoal(id: 'g', name: 'Trip', current: 500, target: 100, icon: '🎯');
      expect(over.progress, 1.0);
      expect(over.isComplete, isTrue);

      const zero =
          SavingsGoal(id: 'g', name: 'Bad', current: 10, target: 0, icon: '🎯');
      expect(zero.progress, 0.0);
    });
  });
}
