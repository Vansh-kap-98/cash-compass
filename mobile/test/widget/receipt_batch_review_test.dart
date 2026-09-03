import 'package:cash_compass/logic/receipt_batch_queue.dart';
import 'package:cash_compass/logic/receipt_parser.dart';
import 'package:cash_compass/screens/receipt_batch_review_screen.dart';
import 'package:cash_compass/state/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Batch review: per-row independence, duplicate handling, and the rule that
/// nothing is written until the user says so.
void main() {
  ParsedReceipt receipt({
    double? amount = 12.00,
    String? merchant = 'Corner Market',
    String? currencyCode,
    ReceiptDiscrepancy? discrepancy,
    FieldConfidence confidence = FieldConfidence.high,
  }) =>
      ParsedReceipt(
        amount: amount,
        amountConfidence: confidence,
        merchant: merchant,
        merchantConfidence: FieldConfidence.high,
        category: 'Groceries',
        currencyCode: currencyCode,
        discrepancy: discrepancy,
      );

  BatchEntry entry(
    String id, {
    ParsedReceipt? parsed,
    DateTime? capturedAt,
    BatchStatus status = BatchStatus.done,
  }) =>
      BatchEntry(
        id: id,
        imagePath: '/nonexistent/$id.jpg',
        receipt: parsed ?? receipt(),
        capturedAt: capturedAt,
        status: status,
      );

  void tallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<TestStores> pump(
    WidgetTester tester,
    List<BatchEntry> entries, {
    Future<BatchEntry> Function(BatchEntry)? onRetry,
  }) async {
    tallViewport(tester);
    final stores = TestStores.empty();
    await tester.pumpWidget(
      wrapForTest(
        ReceiptBatchReviewScreen(entries: entries, onRetry: onRetry),
        stores: stores,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return stores;
  }

  group('nothing is saved without confirmation', () {
    testWidgets('the store stays empty until Save is tapped', (tester) async {
      final stores = await pump(tester, [entry('a'), entry('b')]);

      expect(
        stores.finance.transactions,
        isEmpty,
        reason: 'a batch that auto-saved would write five OCR guesses at once, '
            'and there is no way to delete a transaction yet',
      );

      await tester.tap(find.textContaining('Save 2 receipts'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(stores.finance.transactions, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('rows are independent', () {
    testWidgets('editing one row does not touch the others', (tester) async {
      final stores = await pump(tester, [
        entry('a', parsed: receipt(merchant: 'Alpha', amount: 10)),
        entry('b', parsed: receipt(merchant: 'Beta', amount: 20)),
      ]);

      await tester.enterText(find.widgetWithText(TextField, 'Alpha'), 'Edited');
      await tester.pump();

      await tester.tap(find.textContaining('Save 2 receipts'));
      await tester.pump(const Duration(milliseconds: 600));

      final names = stores.finance.transactions.map((t) => t.name).toSet();
      expect(names, containsAll(['Edited', 'Beta']));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('skipping one row saves only the rest', (tester) async {
      final stores = await pump(tester, [
        entry('a', parsed: receipt(merchant: 'Alpha')),
        entry('b', parsed: receipt(merchant: 'Beta')),
      ]);

      await tester.tap(find.text('Skip').first);
      await tester.pump();

      expect(find.textContaining('Save 1 receipt'), findsOneWidget);

      await tester.tap(find.textContaining('Save 1 receipt'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(stores.finance.transactions, hasLength(1));
      expect(stores.finance.transactions.single.name, 'Beta');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a failed row does not block the readable ones',
        (tester) async {
      final stores = await pump(tester, [
        entry('bad', parsed: null, status: BatchStatus.failed),
        entry('good', parsed: receipt(merchant: 'Readable')),
      ]);

      expect(find.text('Could not read this one'), findsOneWidget);
      expect(find.textContaining('Save 1 receipt'), findsOneWidget);

      await tester.tap(find.textContaining('Save 1 receipt'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(stores.finance.transactions.single.name, 'Readable');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('retry replaces one row only', (tester) async {
      await pump(
        tester,
        [
          entry('bad', parsed: null, status: BatchStatus.failed),
          entry('good', parsed: receipt(merchant: 'Untouched')),
        ],
        onRetry: (e) async => e.copyWith(
          receipt: receipt(merchant: 'Recovered'),
          status: BatchStatus.done,
        ),
      );

      expect(find.text('Could not read this one'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Could not read this one'), findsNothing);
      expect(find.widgetWithText(TextField, 'Recovered'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Untouched'),
        findsOneWidget,
        reason: 'the other row must survive a retry untouched',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('duplicates', () {
    testWidgets('a repeated receipt is flagged but not removed',
        (tester) async {
      final day = DateTime(2026, 8, 21, 14);
      await pump(tester, [
        entry('first', capturedAt: day),
        entry('second', capturedAt: day),
      ]);

      expect(find.textContaining('Looks like a repeat'), findsOneWidget);
      expect(
        find.textContaining('Save 2 receipts'),
        findsOneWidget,
        reason: 'flagged, not dropped — a false positive must not silently '
            'lose a real expense',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('skipping the flagged copy saves one', (tester) async {
      final day = DateTime(2026, 8, 21, 14);
      final stores = await pump(tester, [
        entry('first', capturedAt: day),
        entry('second', capturedAt: day),
      ]);

      await tester.tap(find.text('Skip').last);
      await tester.pump();
      await tester.tap(find.textContaining('Save 1 receipt'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(stores.finance.transactions, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('dates', () {
    testWidgets('the EXIF capture date is used, not today', (tester) async {
      final shot = DateTime(2026, 8, 21, 14);
      final stores = await pump(tester, [entry('a', capturedAt: shot)]);

      await tester.tap(find.textContaining('Save 1 receipt'));
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        stores.finance.transactions.single.date,
        '2026-08-21',
        reason: 'a receipt photographed on Tuesday must not be dated the night '
            'the batch was scanned',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a missing capture date is visible, not silent',
        (tester) async {
      await pump(tester, [entry('a')]);

      expect(
        find.text('no photo date'),
        findsOneWidget,
        reason: 'the fallback must be surfaced so the user can correct it',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('currency', () {
    testWidgets('a foreign receipt is converted into the active currency',
        (tester) async {
      tallViewport(tester);
      final stores = TestStores.empty();
      await stores.currency.setCurrency(AppCurrency.inr);

      await tester.pumpWidget(
        wrapForTest(
          ReceiptBatchReviewScreen(
            entries: [
              entry('a', parsed: receipt(amount: 10, currencyCode: 'USD')),
            ],
          ),
          stores: stores,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Fallback rate is 83.5 INR to the dollar.
      expect(find.widgetWithText(TextField, '835.00'), findsOneWidget);
      expect(find.textContaining('10.00 USD converted'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('discrepancies are surfaced', () {
    testWidgets('a total that disagrees with its items is called out',
        (tester) async {
      await pump(tester, [
        entry(
          'a',
          parsed: receipt(
            discrepancy: const ItemSumDiscrepancy(
              labelled: 95,
              itemSum: 20,
            ),
          ),
        ),
      ]);

      expect(find.textContaining('does not match the items'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
