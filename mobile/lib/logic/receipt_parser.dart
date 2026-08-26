/// Extracts an amount, merchant, and category from receipt OCR text.
///
/// Deliberately Flutter-free and ML-Kit-free: the recognizer hands us lines of
/// text, and everything below is pure string work. That keeps the interesting
/// half testable against fixture text without a camera, an emulator, or a
/// native dependency.
///
/// Everything here runs on-device. No receipt image or extracted text leaves
/// the phone.
library;

import '../models/transaction.dart';

/// How much to trust a single extracted field.
///
/// Surfaced in the UI so an OCR guess never looks as certain as something the
/// user typed.
enum FieldConfidence { high, medium, low, none }

extension FieldConfidenceLabel on FieldConfidence {
  /// True when the value deserves a "please confirm" hint.
  bool get needsReview =>
      this == FieldConfidence.low || this == FieldConfidence.medium;
}

/// The result of reading a receipt.
class ParsedReceipt {
  const ParsedReceipt({
    this.amount,
    this.amountConfidence = FieldConfidence.none,
    this.merchant,
    this.merchantConfidence = FieldConfidence.none,
    this.category,
    this.categoryConfidence = FieldConfidence.none,
    this.suggestsSubscription = false,
    this.rawText = '',
    this.imagePath,
  });

  /// Amount as printed on the receipt — in whatever currency the receipt is in,
  /// which the caller converts. Null when nothing usable was found.
  final double? amount;
  final FieldConfidence amountConfidence;

  final String? merchant;
  final FieldConfidence merchantConfidence;

  /// One of [expenseCategories], never a value outside that list.
  final String? category;
  final FieldConfidence categoryConfidence;

  /// True when this merchant and amount already look like a recurring charge
  /// in the user's history.
  final bool suggestsSubscription;

  /// Recognised text, kept for debugging and capped in size.
  final String rawText;

  final String? imagePath;

  /// True when nothing useful came back, so the caller can fall through to
  /// plain manual entry.
  bool get isEmpty => amount == null && merchant == null;

  ParsedReceipt copyWith({
    bool? suggestsSubscription,
    String? imagePath,
  }) =>
      ParsedReceipt(
        amount: amount,
        amountConfidence: amountConfidence,
        merchant: merchant,
        merchantConfidence: merchantConfidence,
        category: category,
        categoryConfidence: categoryConfidence,
        suggestsSubscription: suggestsSubscription ?? this.suggestsSubscription,
        rawText: rawText,
        imagePath: imagePath ?? this.imagePath,
      );

  static const empty = ParsedReceipt();
}

/// Upper bounds so a long receipt cannot balloon memory.
///
/// A supermarket receipt with a hundred line items is realistic; storing all of
/// it on the transaction is not.
const _maxLines = 300;
const _maxRawTextChars = 4000;

/// Lines that mark a total, strongest first.
///
/// Order matters: "grand total" beats "total", and "subtotal" is deliberately
/// absent — matching it would pick the pre-tax figure.
const _totalKeywords = <String>[
  'grand total',
  'amount due',
  'balance due',
  'total due',
  'total',
  'balance',
];

/// Words that disqualify a line from being the final total.
const _totalNegatives = <String>[
  'subtotal',
  'sub total',
  'tax',
  'vat',
  'gst',
  'change',
  'cash',
  'tender',
  'savings',
  'discount',
];

/// Merchant keyword -> category. Values must exist in [expenseCategories].
///
/// Kept here rather than in the model because it is a heuristic, not a domain
/// fact — but validated against the real category list so it cannot drift.
const Map<String, String> _categoryKeywords = {
  // Food
  'restaurant': 'Food', 'cafe': 'Food', 'coffee': 'Food', 'grill': 'Food',
  'pizza': 'Food', 'burger': 'Food', 'bakery': 'Food', 'kitchen': 'Food',
  'diner': 'Food', 'bistro': 'Food', 'starbucks': 'Food', 'mcdonald': 'Food',
  // Groceries
  'supermarket': 'Groceries', 'grocery': 'Groceries', 'market': 'Groceries',
  'mart': 'Groceries', 'foods': 'Groceries', 'tesco': 'Groceries',
  'aldi': 'Groceries', 'lidl': 'Groceries', 'kroger': 'Groceries',
  // Transport
  'uber': 'Transport', 'lyft': 'Transport', 'taxi': 'Transport',
  'cab': 'Transport', 'metro': 'Transport', 'transit': 'Transport',
  'railway': 'Transport', 'petrol': 'Transport', 'fuel': 'Transport',
  'gas station': 'Transport', 'shell': 'Transport', 'parking': 'Transport',
  // Health
  'pharmacy': 'Health', 'chemist': 'Health', 'cvs': 'Health',
  'walgreens': 'Health', 'clinic': 'Health', 'hospital': 'Health',
  'dental': 'Health', 'optic': 'Health',
  // Entertainment
  'cinema': 'Entertainment', 'theatre': 'Entertainment',
  'theater': 'Entertainment', 'netflix': 'Entertainment',
  'spotify': 'Entertainment', 'games': 'Entertainment',
  // Shopping
  'boutique': 'Shopping', 'apparel': 'Shopping', 'clothing': 'Shopping',
  'fashion': 'Shopping', 'store': 'Shopping', 'shop': 'Shopping',
  // Utilities
  'electric': 'Utilities', 'utility': 'Utilities', 'broadband': 'Utilities',
  'telecom': 'Utilities', 'mobile': 'Utilities', 'energy': 'Utilities',
  // Travel
  'hotel': 'Travel', 'airlines': 'Travel', 'airways': 'Travel',
  'hostel': 'Travel', 'travel': 'Travel',
  // Education
  'books': 'Education', 'bookstore': 'Education', 'university': 'Education',
  'college': 'Education', 'stationery': 'Education',
};

/// The category used when nothing matches.
///
/// 'Other' is the app's existing default — a guess dressed up as a real
/// category would be worse than admitting we don't know.
const String defaultReceiptCategory = 'Other';

/// Every category the keyword map can produce. Exposed so a test can assert
/// none of them drifted out of [expenseCategories].
Set<String> get receiptCategoryTargets => _categoryKeywords.values.toSet();

/// Matches a money-shaped number: optional symbol, thousands separators,
/// and a 1–2 digit fractional part.
final RegExp _amountPattern = RegExp(
  r'(?:[$£€₹]\s*)?(\d{1,3}(?:[,\s]\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
);

/// Lines that look like a phone number, postcode, or street address rather
/// than a merchant name.
final RegExp _phonePattern = RegExp(r'(\+?\d[\d\s().-]{6,}\d)');
final RegExp _addressPattern = RegExp(
  r'\b(street|st\.?|road|rd\.?|avenue|ave\.?|lane|ln\.?|suite|floor|'
  r'block|sector|nagar|marg|po box|zip|postcode)\b',
  caseSensitive: false,
);
final RegExp _hasLetters = RegExp(r'[A-Za-z]');

/// Reads a receipt from already-recognised [lines], top to bottom.
///
/// Pure: no IO, no plugin, no clock. The OCR step lives in the scanner that
/// calls this.
ParsedReceipt parseReceiptLines(
  List<String> lines, {
  String? imagePath,
}) {
  final cleaned = <String>[];
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    cleaned.add(line);
    if (cleaned.length >= _maxLines) break;
  }

  if (cleaned.isEmpty) {
    return ParsedReceipt(imagePath: imagePath);
  }

  final rawText = _capped(cleaned.join('\n'));
  final amount = _extractAmount(cleaned);
  final merchant = _extractMerchant(cleaned);
  final category = _guessCategory(merchant.value, cleaned);

  return ParsedReceipt(
    amount: amount.value,
    amountConfidence: amount.confidence,
    merchant: merchant.value,
    merchantConfidence: merchant.confidence,
    category: category.value,
    categoryConfidence: category.confidence,
    rawText: rawText,
    imagePath: imagePath,
  );
}

String _capped(String text) => text.length <= _maxRawTextChars
    ? text
    : '${text.substring(0, _maxRawTextChars)}…';

typedef _Guess<T> = ({T? value, FieldConfidence confidence});

// ------------------------------------------------------------------- amount

_Guess<double> _extractAmount(List<String> lines) {
  // Search bottom-up: totals sit near the end, and when a receipt prints
  // "Total" then "Total after tip", the later one is the real figure.
  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i];
    final lower = line.toLowerCase();

    if (_totalNegatives.any(lower.contains)) continue;
    if (!_totalKeywords.any(lower.contains)) continue;

    // The amount is usually on the keyword line; if not, try the next line
    // down, which covers receipts that print the label and value separately.
    final onLine = _lastAmountIn(line);
    if (onLine != null) {
      return (value: onLine, confidence: FieldConfidence.high);
    }

    if (i + 1 < lines.length) {
      final below = _lastAmountIn(lines[i + 1]);
      if (below != null) {
        return (value: below, confidence: FieldConfidence.medium);
      }
    }
  }

  // Nothing labelled. The largest money-shaped number is a decent guess on a
  // simple receipt and a bad one on a complex bill, so it is marked low and
  // the UI asks the user to confirm.
  double? largest;
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (_totalNegatives.any(lower.contains)) continue;
    for (final match in _amountPattern.allMatches(line)) {
      final value = _toDouble(match.group(1));
      if (value == null) continue;
      if (largest == null || value > largest) largest = value;
    }
  }

  if (largest == null || largest <= 0) {
    return (value: null, confidence: FieldConfidence.none);
  }
  return (value: largest, confidence: FieldConfidence.low);
}

double? _lastAmountIn(String line) {
  double? found;
  for (final match in _amountPattern.allMatches(line)) {
    final value = _toDouble(match.group(1));
    if (value != null && value > 0) found = value;
  }
  return found;
}

double? _toDouble(String? raw) {
  if (raw == null) return null;
  // Strip thousands separators; the pattern only admits '.' as a decimal mark.
  final normalised = raw.replaceAll(',', '').replaceAll(' ', '');
  final value = double.tryParse(normalised);
  if (value == null || !value.isFinite) return null;
  return value;
}

// ----------------------------------------------------------------- merchant

_Guess<String> _extractMerchant(List<String> lines) {
  // Merchants print their name at the top, above the address and phone block.
  final window = lines.take(5);
  for (final line in window) {
    if (!_hasLetters.hasMatch(line)) continue;
    if (_phonePattern.hasMatch(line)) continue;
    if (_addressPattern.hasMatch(line)) continue;
    // A line that is mostly digits is a till number or a date, not a name.
    final letters = _hasLetters.allMatches(line).length;
    if (letters < line.length / 2) continue;

    final name = _titleCase(line);
    if (name.isEmpty) continue;

    // First line is the strongest signal; further down is a weaker guess.
    final isFirst = line == lines.first;
    return (
      value: name,
      confidence: isFirst ? FieldConfidence.high : FieldConfidence.medium,
    );
  }
  return (value: null, confidence: FieldConfidence.none);
}

String _titleCase(String input) {
  final trimmed = input.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (trimmed.isEmpty) return '';
  return trimmed
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
}

// ----------------------------------------------------------------- category

_Guess<String> _guessCategory(String? merchant, List<String> lines) {
  // The merchant name is the strongest signal.
  if (merchant != null) {
    final hit = _matchCategory(merchant.toLowerCase());
    if (hit != null) return (value: hit, confidence: FieldConfidence.high);
  }

  // Otherwise look through the line items, which often name the goods.
  final body = lines.join(' ').toLowerCase();
  final hit = _matchCategory(body);
  if (hit != null) return (value: hit, confidence: FieldConfidence.low);

  // Never guess: an unhelpful-but-honest default beats a confident wrong one.
  return (value: defaultReceiptCategory, confidence: FieldConfidence.none);
}

String? _matchCategory(String haystack) {
  String? best;
  var bestLength = 0;
  _categoryKeywords.forEach((keyword, category) {
    // Longest keyword wins, so "gas station" beats "gas" if both were present.
    if (keyword.length > bestLength && haystack.contains(keyword)) {
      best = category;
      bestLength = keyword.length;
    }
  });
  return best;
}
