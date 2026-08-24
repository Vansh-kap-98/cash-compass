/// Detects recurring charges from transaction history.
///
/// Port of `widgets/SubscriptionTracker.tsx`. Pure Dart so the detection rules
/// can be unit-tested directly.
library;

import '../models/transaction.dart';


/// A merchant charging on a roughly monthly cadence.
class DetectedSubscription {
  const DetectedSubscription({
    required this.name,
    required this.averageAmount,
    required this.chargeCount,
    required this.averageIntervalDays,
    required this.lastCharged,
  });

  /// Display name, taken from the most recent charge.
  final String name;
  final double averageAmount;
  final int chargeCount;
  final double averageIntervalDays;
  final String lastCharged;

  /// Rough yearly cost if it keeps recurring.
  double get annualCost => averageAmount * 12;
}

/// Normalises a merchant name so "Netflix 04/2026" and "NETFLIX payment"
/// group together.
///
/// Strips digits, punctuation, and the filler words the web app removes.
/// Words that describe the charge rather than the merchant.
const _noiseWords = {'payment', 'subscription', 'monthly'};

String merchantSignature(String name) {
  // A single character walk rather than four `replaceAll` passes. The previous
  // version constructed four RegExp objects *per call*, and this runs once per
  // transaction — regex compilation dominated the whole detection pass.
  final buffer = StringBuffer();
  final word = StringBuffer();

  void flushWord() {
    if (word.isEmpty) return;
    final w = word.toString();
    word.clear();
    if (_noiseWords.contains(w)) return;
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(w);
  }

  for (var i = 0; i < name.length; i++) {
    final c = name.codeUnitAt(i);
    // Fold A-Z to a-z; treat everything that is not a letter as a separator,
    // which covers digits, punctuation, and whitespace in one branch.
    if (c >= 0x41 && c <= 0x5A) {
      word.writeCharCode(c + 32);
    } else if (c >= 0x61 && c <= 0x7A) {
      word.writeCharCode(c);
    } else {
      flushWord();
    }
  }
  flushWord();

  return buffer.toString();
}

/// Whether adding this charge would make the merchant look like a subscription.
///
/// Used by the receipt scanner to warn *before* saving. It deliberately runs
/// the real [detectSubscriptions] over history-plus-candidate rather than
/// reimplementing the cadence and amount rules, so there is exactly one
/// definition of "is a subscription" in the app.
bool wouldBeSubscription({
  required List<FinanceTransaction> history,
  required String merchant,
  required double amount,
  required String date,
}) {
  final signature = merchantSignature(merchant);
  if (signature.isEmpty || amount <= 0) return false;

  final candidate = FinanceTransaction(
    id: 'candidate',
    name: merchant,
    amount: amount,
    type: TransactionType.expense,
    category: 'Other',
    date: date,
  );

  return detectSubscriptions([...history, candidate])
      .any((s) => merchantSignature(s.name) == signature);
}

/// Finds merchants charged on a 27–33 day cadence with consistent amounts.
///
/// Both thresholds come from the web app: the day window tolerates months of
/// different lengths, and amounts must sit within 15% of the average so a
/// variable bill isn't mistaken for a subscription.
List<DetectedSubscription> detectSubscriptions(
  List<FinanceTransaction> transactions,
) {
  final groups = <String, List<FinanceTransaction>>{};
  for (final t in transactions) {
    if (!t.isExpense) continue;
    final key = merchantSignature(t.name);
    if (key.isEmpty) continue;
    groups.putIfAbsent(key, () => []).add(t);
  }

  final detected = <DetectedSubscription>[];

  for (final entry in groups.entries) {
    final charges = entry.value;
    if (charges.length < 2) continue;

    // Cheap rejection before any date parsing.
    //
    // Charges at a 27-day minimum spacing can only fit (span / 27) + 1 times
    // into the period they cover. An everyday category like "lunch" has
    // hundreds of entries over a few months and fails that immediately — but
    // the old code parsed and sorted every one of them first, only to bail on
    // the first gap check. ISO dates compare correctly as strings, so the span
    // costs two parses rather than one per charge.
    var minDate = charges.first.date;
    var maxDate = charges.first.date;
    for (final t in charges) {
      if (t.date.compareTo(minDate) < 0) minDate = t.date;
      if (t.date.compareTo(maxDate) > 0) maxDate = t.date;
    }
    final start = DateTime.tryParse(minDate);
    final end = DateTime.tryParse(maxDate);
    if (start == null || end == null) continue;
    final spanDays = end.difference(start).inDays;
    if (charges.length > spanDays / 27 + 1) continue;

    final dated = charges
        .map((t) => (tx: t, date: t.parsedDate))
        .where((e) => e.date != null)
        .toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    if (dated.length < 2) continue;

    // Every gap must look monthly — one irregular gap disqualifies the group.
    var intervalTotal = 0.0;
    var monthly = true;
    for (var i = 1; i < dated.length; i++) {
      final gap = dated[i].date!.difference(dated[i - 1].date!).inDays;
      if (gap < 27 || gap > 33) {
        monthly = false;
        break;
      }
      intervalTotal += gap;
    }
    if (!monthly) continue;

    final average =
        charges.fold(0.0, (sum, t) => sum + t.amount) / charges.length;
    if (average <= 0) continue;

    final consistent = charges.every(
      (t) => (t.amount - average).abs() / average <= 0.15,
    );
    if (!consistent) continue;

    detected.add(DetectedSubscription(
      name: dated.last.tx.name,
      averageAmount: average,
      chargeCount: charges.length,
      averageIntervalDays: intervalTotal / (dated.length - 1),
      lastCharged: dated.last.tx.date,
    ));
  }

  detected.sort((a, b) => b.averageAmount.compareTo(a.averageAmount));
  return detected;
}
