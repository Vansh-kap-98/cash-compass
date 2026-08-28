import 'package:cash_compass/state/currency_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget/harness.dart';

/// Guards the store-then-display round trip.
///
/// Regression test for a real report: entering 50,000 with the app on INR
/// showed 49,999.83 back. The cause was `convertToUsd` rounding to cents
/// before persisting — one US cent is nearly a rupee, so quantising the
/// stored value lost up to ~₹0.48 on every entry, in a consistent direction
/// rather than cancelling out.
///
/// The property that matters is not "conversion is correct" but "what the
/// user typed is what the user sees again". Those are different tests, and
/// only the second one catches this.
void main() {
  late CurrencyProvider currency;

  setUp(() {
    currency = CurrencyProvider(FakePrefs());
  });

  /// What the app does end to end: convert for storage, convert back to show.
  double roundTrip(double typed) =>
      currency.convertFromUsd(currency.convertToUsd(typed));

  group('a typed amount survives the trip to storage and back', () {
    for (final amount in [50000.0, 1.0, 99.99, 12345.67, 0.01, 250000.0]) {
      test('$amount INR', () async {
        await currency.setCurrency(AppCurrency.inr);
        expect(
          roundTrip(amount),
          closeTo(amount, 0.01),
          reason: 'what the user typed must be what they see again',
        );
      });
    }

    test('the exact figure from the bug report', () async {
      await currency.setCurrency(AppCurrency.inr);
      expect(
        roundTrip(50000),
        closeTo(50000, 0.01),
        reason: '50000 INR previously came back as 49999.83',
      );
    });

    test('holds for RUB too', () async {
      await currency.setCurrency(AppCurrency.rub);
      expect(roundTrip(50000), closeTo(50000, 0.01));
    });

    test('USD is untouched by conversion', () async {
      await currency.setCurrency(AppCurrency.usd);
      expect(roundTrip(50000), 50000);
    });
  });

  test('storage keeps more precision than two decimal places', () async {
    await currency.setCurrency(AppCurrency.inr);
    final stored = currency.convertToUsd(50000);
    expect(
      stored,
      isNot(closeTo(double.parse(stored.toStringAsFixed(2)), 1e-9)),
      reason: 'rounding the stored value to cents is what caused the drift; '
          'if this ever passes again the fix has been undone',
    );
  });

  test('display is still rounded to two decimals', () async {
    await currency.setCurrency(AppCurrency.inr);
    final shown = currency.convertFromUsd(523.34100900146);
    expect(
      shown,
      closeTo(double.parse(shown.toStringAsFixed(2)), 1e-9),
      reason: 'the fix must not leak full precision into what a human reads',
    );
  });
}
