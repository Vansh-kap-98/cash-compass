import 'package:cash_compass/logic/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Total-detection hardening, currency identification, and line items.
///
/// The headline case is a receipt where CASH and CHANGE are both currency
/// formatted and numerically larger than the real total. A "largest number"
/// fallback picks the wrong figure on that shape unless payment lines are
/// excluded before it runs.
ParsedReceipt parse(String text) => parseReceiptLines(text.split('\n'));

void main() {
  group('cash and change never outrank the total', () {
    // The exact shape from the report: total 117, cash 200, change 83,
    // seven items summing to 117.
    const reported = '''
CORNER MARKET
123 High Street
Bread            4.00
Milk             3.50
Eggs             6.00
Cheese          12.00
Coffee          28.50
Chicken         41.00
Rice            22.00
SUBTOTAL       117.00
TOTAL          117.00
CASH           200.00
CHANGE          83.00
''';

    test('picks the total, not the cash tendered', () {
      final r = parse(reported);
      expect(r.amount, 117.00);
      expect(
        r.amount,
        isNot(200.00),
        reason: 'CASH is larger and currency-formatted; it must be excluded',
      );
    });

    test('three agreeing signals earn high confidence', () {
      final r = parse(reported);
      expect(r.amountConfidence, FieldConfidence.high);
      expect(
        r.evidence,
        TotalEvidence.corroborated,
        reason: 'the label, cash − change, and the item sum all say 117',
      );
      expect(r.discrepancy, isNull);
    });

    test('the item sum is available and matches', () {
      final r = parse(reported);
      expect(r.lineItems, hasLength(7));
      expect(r.lineItemTotal, closeTo(117.00, 0.01));
    });

    test('cash − change carries the total when no label survives', () {
      final r = parse('''
CORNER MARKET
Bread            4.00
Chicken         41.00
CASH           200.00
CHANGE          83.00
''');
      expect(
        r.amount,
        117.00,
        reason: 'the receipt did the arithmetic; use it rather than guessing '
            'the largest item',
      );
      expect(r.evidence, TotalEvidence.derivedFromCash);
    });

    test('a card ending is never read as the total', () {
      final r = parse('''
CORNER MARKET
Coffee          28.50
TOTAL           28.50
VISA ending in 4242
''');
      expect(r.amount, 28.50);
    });
  });

  group('priority ranking', () {
    test('an unambiguous label beats a bare total further down', () {
      final r = parse('''
SHOP
TOTAL           12.34
GRAND TOTAL     19.99
''');
      expect(r.amount, 19.99);
    });

    test('subtotal never wins over total', () {
      final r = parse('''
SHOP
SUBTOTAL        99.99
TAX              5.00
TOTAL           12.34
''');
      expect(r.amount, 12.34);
    });

    test('the tip-adjusted total still wins within its tier', () {
      final r = parse('''
THE GRILL HOUSE
Total            40.00
Tip               6.00
Total after tip  46.00
''');
      expect(
        r.amount,
        46.00,
        reason: 'same tier, so the lowest line wins — the pre-tip figure is '
            'printed first',
      );
    });

    test('"Total Tax" is not mistaken for the total', () {
      final r = parse('''
SHOP
Total Tax        5.00
TOTAL           55.00
''');
      expect(r.amount, 55.00);
    });
  });

  group('cross-checks change confidence', () {
    test('items disagreeing with the total lowers confidence and explains', () {
      final r = parse('''
SHOP
Widget          10.00
Gadget          10.00
TOTAL           95.00
''');
      expect(r.amount, 95.00);
      expect(r.amountConfidence, FieldConfidence.medium);
      expect(r.evidence, TotalEvidence.conflicting);
      expect(
        r.discrepancy,
        contains('does not match the items'),
        reason: 'the review screen shows this instead of silently trusting it',
      );
    });

    test('a total below the item sum is worse than one above it', () {
      // Above the sum is ordinary — tax and tip are often not itemised.
      final above = parse('SHOP\nWidget 10.00\nTOTAL 12.00');
      // Below the sum cannot be explained that way.
      final below = parse('SHOP\nWidget 10.00\nGadget 10.00\nTOTAL 5.00');

      expect(above.amountConfidence, FieldConfidence.medium);
      expect(below.amountConfidence, FieldConfidence.low);
    });

    test('cash arithmetic overrides a contradicting label', () {
      final r = parse('''
SHOP
TOTAL           11.00
CASH           200.00
CHANGE          83.00
''');
      expect(
        r.amount,
        117.00,
        reason: 'the receipt computed cash − change itself; a misread label '
            'should not beat it',
      );
      expect(r.evidence, TotalEvidence.conflicting);
      expect(r.discrepancy, contains('disagrees'));
    });
  });

  group('currency identification', () {
    test('a euro symbol beside the total', () {
      expect(parse('CAFE PARIS\nTOTAL  €24.50').currencyCode, 'EUR');
    });

    test('a rupee symbol', () {
      expect(parse('CHAI CORNER\nTOTAL  ₹450.00').currencyCode, 'INR');
    });

    test('an ISO code printed as text', () {
      expect(parse('SHOP\nTOTAL 24.50 USD').currencyCode, 'USD');
    });

    test('no marker yields null, not a default', () {
      final r = parse('SHOP\nTOTAL 24.50');
      expect(
        r.currencyCode,
        isNull,
        reason: 'null lets the caller substitute the user\'s own currency; '
            'defaulting to USD here would be wrong for most of the world',
      );
    });

    test('fine print far from the total is ignored', () {
      final r = parse('''
SHOP
All prices shown in USD where applicable
Coffee           4.00
Pastry           3.00
Bread            2.00
Juice            5.00
Water            1.00
TOTAL          ₹450.00
''');
      expect(
        r.currencyCode,
        'INR',
        reason: 'the symbol beside the total beats a mention in the header',
      );
    });

    test('a word starting with a currency code is not a match', () {
      final r = parse('SHOP\nUSDA ORGANIC BEANS 4.00\nTOTAL 4.00');
      expect(r.currencyCode, isNull);
    });
  });

  group('line items', () {
    test('quantity prefixes are parsed off the description', () {
      final r = parse('''
SHOP
2 x Coffee       9.00
Bread            4.00
TOTAL           13.00
''');
      expect(r.lineItems, hasLength(2));
      expect(r.lineItems.first.quantity, 2);
      expect(r.lineItems.first.description, 'Coffee');
      expect(r.lineItems.first.price, 9.00);
    });

    test('totals, tax, and payment rows are not items', () {
      final r = parse('''
SHOP
Bread            4.00
SUBTOTAL         4.00
TAX              0.40
TOTAL            4.40
CASH            10.00
CHANGE           5.60
''');
      expect(r.lineItems.map((i) => i.description), ['Bread']);
    });

    test('stray numbers without a description are not items', () {
      final r = parse('''
SHOP
20260821 0931 4471
Bread            4.00
TOTAL            4.00
''');
      expect(r.lineItems.map((i) => i.description), ['Bread']);
    });
  });

  group('regressions from v1 still hold', () {
    test('a labelled total with no other signal is still high confidence', () {
      final r = parse('BLUE BOTTLE COFFEE\nTotal            8.37');
      expect(r.amount, 8.37);
      expect(r.amountConfidence, FieldConfidence.high);
    });

    test('empty input is still empty', () {
      expect(parse('').isEmpty, isTrue);
    });

    test('merchant extraction is unaffected', () {
      final r = parse('''
+44 20 7946 0958
14 Baker Street
Tesco Express
Total 22.10
''');
      expect(r.merchant, 'Tesco Express');
    });
  });
}
