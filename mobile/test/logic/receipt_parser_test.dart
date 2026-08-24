import 'package:cash_compass/logic/receipt_parser.dart';
import 'package:cash_compass/logic/subscriptions.dart';
import 'package:cash_compass/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture OCR text rather than real images.
///
/// This isolates the extraction rules from ML Kit entirely: no camera, no
/// emulator, no native dependency, and a failure points at the parser rather
/// than at the recognizer.
void main() {
  ParsedReceipt parse(String text) =>
      parseReceiptLines(text.trim().split('\n'));

  group('amount extraction', () {
    test('prefers a labelled total', () {
      final r = parse('''
BLUE BOTTLE COFFEE
123 Market Street
Latte            4.50
Croissant        3.25
Subtotal         7.75
Tax              0.62
Total            8.37
''');
      expect(r.amount, 8.37);
      expect(r.amountConfidence, FieldConfidence.high);
    });

    test('ignores subtotal and tax lines', () {
      final r = parse('''
Shop
Subtotal        99.99
Tax              5.00
Total           12.34
''');
      expect(r.amount, 12.34, reason: 'subtotal must not win over total');
    });

    test('takes the last total when a tip line follows', () {
      // Receipts print the pre-tip total first, so reading bottom-up matters.
      final r = parse('''
The Grill House
Total            40.00
Tip               6.00
Total after tip  46.00
''');
      expect(r.amount, 46.00);
    });

    test('handles currency symbols and thousands separators', () {
      final r = parse('''
Electronics World
Grand Total    \$1,299.99
''');
      expect(r.amount, 1299.99);
      expect(r.amountConfidence, FieldConfidence.high);
    });

    test('reads the value from the line below the label', () {
      final r = parse('''
Corner Store
TOTAL
15.75
''');
      expect(r.amount, 15.75);
      expect(r.amountConfidence, FieldConfidence.medium);
    });

    test('falls back to the largest number, marked low confidence', () {
      final r = parse('''
Mystery Shop
item one      3.00
item two     11.50
item three    7.25
''');
      expect(r.amount, 11.50);
      expect(
        r.amountConfidence,
        FieldConfidence.low,
        reason: 'a guess must not look as certain as a labelled total',
      );
    });
  });

  group('merchant extraction', () {
    test('takes the top line and title-cases it', () {
      final r = parse('''
BLUE BOTTLE COFFEE
123 Market Street
Total 8.37
''');
      expect(r.merchant, 'Blue Bottle Coffee');
      expect(r.merchantConfidence, FieldConfidence.high);
    });

    test('skips phone numbers and addresses', () {
      final r = parse('''
+44 20 7946 0958
14 Baker Street
Tesco Express
Total 22.10
''');
      expect(r.merchant, 'Tesco Express');
      expect(r.merchantConfidence, FieldConfidence.medium);
    });

    test('skips lines that are mostly digits', () {
      final r = parse('''
20260821 0931 4471
Pharmacy Plus
Total 9.99
''');
      expect(r.merchant, 'Pharmacy Plus');
    });
  });

  group('category guessing', () {
    test('maps a merchant keyword to a category', () {
      expect(parse('Joe\'s Pizza Kitchen\nTotal 20.00').category, 'Food');
      expect(parse('Uber Trip\nTotal 14.20').category, 'Transport');
      expect(parse('CVS Pharmacy\nTotal 8.10').category, 'Health');
      expect(parse('Tesco Supermarket\nTotal 45.00').category, 'Groceries');
    });

    test('defaults to Other rather than guessing', () {
      final r = parse('Zylnor Ltd\nTotal 5.00');
      expect(r.category, defaultReceiptCategory);
      expect(r.categoryConfidence, FieldConfidence.none);
    });

    test('every mapped category is a real expense category', () {
      // Guards against the keyword map drifting away from the app's list.
      for (final category in receiptCategoryTargets) {
        expect(
          expenseCategories,
          contains(category),
          reason: '"$category" is not in expenseCategories',
        );
      }
    });

    test('prefers the longer keyword on overlap', () {
      // "gas station" -> Transport must beat a bare substring match.
      expect(parse('Shell Gas Station\nTotal 60.00').category, 'Transport');
    });
  });

  group('unusable input falls through to manual entry', () {
    test('empty text yields an empty result', () {
      final r = parse('\n   \n');
      expect(r.isEmpty, isTrue);
      expect(r.amount, isNull);
      expect(r.merchant, isNull);
    });

    test('garbled OCR yields no amount', () {
      final r = parse('~~~ \$\$\$ ### ??? ***');
      expect(r.amount, isNull);
      expect(r.amountConfidence, FieldConfidence.none);
    });

    test('non-Latin script is treated as unreadable, not a crash', () {
      // ML Kit's Latin recognizer returns little or nothing for these; the
      // parser must degrade rather than throw.
      final r = parse('スーパーマーケット\n合計 1200');
      expect(r.merchant, isNull, reason: 'no Latin letters to work with');
      expect(() => r.isEmpty, returnsNormally);
    });
  });

  group('bounds', () {
    test('raw text is capped for a very long receipt', () {
      final lines = [
        'Mega Market',
        for (var i = 0; i < 2000; i++) 'Item $i    ${i % 90 + 1}.99',
        'Total 42.00',
      ];
      final r = parseReceiptLines(lines);
      expect(r.rawText.length, lessThanOrEqualTo(4100));
      expect(r.amount, isNotNull, reason: 'still parses despite the cap');
    });
  });

  group('candidate subscription check', () {
    FinanceTransaction charge(String date, double amount) => FinanceTransaction(
          id: 'h-$date',
          name: 'Netflix',
          amount: amount,
          type: TransactionType.expense,
          category: 'Entertainment',
          date: date,
        );

    test('flags a merchant already charging monthly', () {
      final flagged = wouldBeSubscription(
        history: [charge('2026-06-01', 15.99), charge('2026-07-01', 15.99)],
        merchant: 'Netflix',
        amount: 15.99,
        date: '2026-08-01',
      );
      expect(flagged, isTrue);
    });

    test('does not flag a one-off merchant', () {
      final flagged = wouldBeSubscription(
        history: [charge('2026-06-01', 15.99)],
        merchant: 'Corner Bakery',
        amount: 4.50,
        date: '2026-08-01',
      );
      expect(flagged, isFalse);
    });

    test('does not flag when the amount is wildly different', () {
      final flagged = wouldBeSubscription(
        history: [charge('2026-06-01', 15.99), charge('2026-07-01', 15.99)],
        merchant: 'Netflix',
        amount: 99.00,
        date: '2026-08-01',
      );
      expect(
        flagged,
        isFalse,
        reason: 'the ±15% amount rule must still apply to the candidate',
      );
    });
  });
}
