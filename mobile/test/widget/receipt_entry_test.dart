import 'package:cash_compass/logic/receipt_parser.dart';
import 'package:cash_compass/state/currency_provider.dart';
import 'package:cash_compass/widgets/add_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Covers the seam between a scanned receipt and a saved transaction.
///
/// The camera and ML Kit halves need a device and are not testable here. What
/// *is* testable — and is where a mistake would silently corrupt someone's
/// figures — is what happens to a [ParsedReceipt] once it reaches the form:
/// the currency conversion, and whether a low-confidence guess is visibly
/// marked as a guess rather than presented as fact.
void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget host(ParsedReceipt receipt) {
    return Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => AddEntrySheet.show(context, receipt: receipt),
          child: const Text('open'),
        ),
      ),
    );
  }

  const confident = ParsedReceipt(
    amount: 450,
    amountConfidence: FieldConfidence.high,
    merchant: 'Big Bazaar',
    merchantConfidence: FieldConfidence.high,
    category: 'Groceries',
    categoryConfidence: FieldConfidence.high,
    rawText: 'BIG BAZAAR\nTOTAL 450.00',
  );

  testWidgets('a scanned receipt prefills the form', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    await tester.pumpWidget(wrapForTest(host(confident), stores: stores));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Big Bazaar'), findsOneWidget);
    expect(find.text('450.00'), findsOneWidget);
    expect(
      find.text('Check Receipt'),
      findsOneWidget,
      reason: 'a scan must be presented as something to confirm, not as done',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a scanned amount is converted from the active currency',
      (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();
    // Fallback rate is 83.5 INR to the dollar.
    await stores.currency.setCurrency(AppCurrency.inr);

    await tester.pumpWidget(wrapForTest(host(confident), stores: stores));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();

    expect(stores.finance.transactions, hasLength(1));
    final saved = stores.finance.transactions.first;
    expect(
      saved.amount,
      closeTo(450 / 83.5, 0.01),
      reason: 'a receipt read as 450 with the app on INR is 450 INR, not '
          '450 USD — storing it unconverted would inflate it 83-fold',
    );
    expect(saved.category, 'Groceries');
    expect(
      saved.note,
      contains('Scanned receipt'),
      reason: 'the entry must be traceable back to a scan',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a low-confidence field is flagged for review', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    const unsure = ParsedReceipt(
      amount: 99.5,
      // No labelled total was found, so this is the largest number on the page.
      amountConfidence: FieldConfidence.low,
      merchant: 'Corner Shop',
      merchantConfidence: FieldConfidence.high,
      rawText: '',
    );

    await tester.pumpWidget(wrapForTest(host(unsure), stores: stores));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.text('Scanned — please check'),
      findsOneWidget,
      reason: 'the uncertain amount must be marked, and only it — the '
          'confidently-read merchant must not be',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('editing a flagged field clears its hint', (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    const unsure = ParsedReceipt(
      amount: 99.5,
      amountConfidence: FieldConfidence.low,
      rawText: '',
    );

    await tester.pumpWidget(wrapForTest(host(unsure), stores: stores));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Scanned — please check'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Amount (USD)'),
      '120',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Scanned — please check'),
      findsNothing,
      reason: 'once corrected the value is the user\'s, not a guess',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('a suspected subscription is surfaced before saving',
      (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    const recurring = ParsedReceipt(
      amount: 15.99,
      amountConfidence: FieldConfidence.high,
      merchant: 'Netflix',
      merchantConfidence: FieldConfidence.high,
      category: 'Entertainment',
      categoryConfidence: FieldConfidence.high,
      suggestsSubscription: true,
      rawText: '',
    );

    await tester.pumpWidget(wrapForTest(host(recurring), stores: stores));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('looks like a recurring charge'),
      findsOneWidget,
      reason: 'the warning is only useful before the entry is committed',
    );

    await tester.tap(find.text('Save Entry'));
    await tester.pumpAndSettle();

    expect(
      stores.finance.transactions.first.note,
      contains('Recurring: monthly'),
      reason: 'the subscription detector reads recurrence out of the note',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the plain form is unchanged when there is no receipt',
      (tester) async {
    useTallViewport(tester);
    final stores = TestStores.empty();

    await tester.pumpWidget(
      wrapForTest(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => AddEntrySheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
        stores: stores,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Entry'), findsOneWidget);
    expect(find.text('Check Receipt'), findsNothing);
    expect(find.text('Scanned — please check'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
