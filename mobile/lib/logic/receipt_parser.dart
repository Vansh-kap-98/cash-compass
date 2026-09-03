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

/// One `description ... price` row from the body of a receipt.
class ReceiptLineItem {
  const ReceiptLineItem({
    required this.description,
    required this.price,
    this.quantity,
  });

  final String description;

  /// Line price as printed, in the receipt's own currency.
  final double price;

  /// Leading quantity where the receipt printed one (`2 x Coffee`).
  final int? quantity;

  @override
  String toString() => '${quantity == null ? '' : '$quantity x '}'
      '$description = $price';
}

/// Why the parser believes the total it picked.
///
/// A receipt usually states its total more than once — as a labelled line, as
/// `cash - change`, and implicitly as the sum of its items. Recording which of
/// those agreed is what separates a confident read from a lucky one.
enum TotalEvidence {
  /// A labelled total line, corroborated by `cash - change` or the item sum.
  corroborated,

  /// A labelled total line, with nothing available to check it against.
  labelledOnly,

  /// No usable label; the figure came from `cash - change`.
  derivedFromCash,

  /// No label and no arithmetic — the largest non-excluded number on the page.
  guessed,

  /// Signals were found and they disagreed. The value is the best of them.
  conflicting,
}

/// The result of reading a receipt.
/// Why the parser is unsure about the total it chose.
///
/// Holds the conflicting figures, not a sentence: the wording belongs to the
/// review screen and has to change with the language.
sealed class ReceiptDiscrepancy {
  const ReceiptDiscrepancy();
}

/// The printed total disagrees with the receipt's own `cash − change`.
class CashChangeDiscrepancy extends ReceiptDiscrepancy {
  const CashChangeDiscrepancy({required this.labelled, required this.computed});

  /// The figure printed beside the "total" label, if one was read.
  final double? labelled;

  /// What `cash − change` comes to.
  final double? computed;
}

/// The printed total does not match the sum of the line items.
class ItemSumDiscrepancy extends ReceiptDiscrepancy {
  const ItemSumDiscrepancy({required this.labelled, required this.itemSum});

  final double? labelled;
  final double? itemSum;
}

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
    this.currencyCode,
    this.lineItems = const [],
    this.evidence = TotalEvidence.guessed,
    this.discrepancy,
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

  /// ISO code of the currency printed on the receipt, or null when the receipt
  /// carried no symbol or code near its total.
  ///
  /// Null is meaningful and must not be defaulted to USD by the parser — the
  /// caller substitutes the user's active currency, which is a far better guess
  /// than a hardcoded one for someone who never spends dollars.
  final String? currencyCode;

  /// Rows parsed from the body. Empty when the layout was not recognisable,
  /// which is common and not an error.
  final List<ReceiptLineItem> lineItems;

  /// How the total was arrived at, and whether anything corroborated it.
  final TotalEvidence evidence;

  /// Set when independent signals disagreed. Carries the figures rather than a
  /// sentence — the review screen words it in the active language via
  /// `lib/l10n/presenters.dart`.
  final ReceiptDiscrepancy? discrepancy;

  /// True when nothing useful came back, so the caller can fall through to
  /// plain manual entry.
  bool get isEmpty => amount == null && merchant == null;

  /// Sum of the parsed rows, or null when none were parsed.
  double? get lineItemTotal {
    if (lineItems.isEmpty) return null;
    return lineItems.fold<double>(0, (sum, i) => sum + i.price);
  }

  ParsedReceipt copyWith({
    double? amount,
    FieldConfidence? amountConfidence,
    String? merchant,
    String? category,
    bool? suggestsSubscription,
    String? imagePath,
    String? currencyCode,
  }) =>
      ParsedReceipt(
        amount: amount ?? this.amount,
        amountConfidence: amountConfidence ?? this.amountConfidence,
        merchant: merchant ?? this.merchant,
        merchantConfidence: merchantConfidence,
        category: category ?? this.category,
        categoryConfidence: categoryConfidence,
        suggestsSubscription: suggestsSubscription ?? this.suggestsSubscription,
        rawText: rawText,
        imagePath: imagePath ?? this.imagePath,
        currencyCode: currencyCode ?? this.currencyCode,
        lineItems: lineItems,
        evidence: evidence,
        discrepancy: discrepancy,
      );

  static const empty = ParsedReceipt();
}

/// Upper bounds so a long receipt cannot balloon memory.
///
/// A supermarket receipt with a hundred line items is realistic; storing all of
/// it on the transaction is not.
const _maxLines = 300;
const _maxRawTextChars = 4000;

/// Total labels in priority tiers, strongest first.
///
/// Ranked rather than first-match: an unambiguous label anywhere on the receipt
/// beats a bare "total" further down. Within a tier the *lowest* line wins,
/// which is what makes "Total 40.00 / Tip 6.00 / Total after tip 46.00" resolve
/// to 46.00.
///
/// "subtotal" is deliberately absent — matching it would pick the pre-tax
/// figure.
const _totalKeywordTiers = <List<String>>[
  ['grand total', 'total amount', 'amount due', 'balance due', 'total due'],
  ['total', 'balance'],
];

/// Every total label, flattened, for the line-item scan to skip.
final Set<String> _allTotalKeywords = {
  for (final tier in _totalKeywordTiers) ...tier,
};

/// Words that disqualify a line from being the final total.
///
/// This runs *before* any ranking or fallback. Cash, change, and tender lines
/// are the important ones: they are currency-formatted and routinely larger
/// than the real total (`TOTAL 117.00 / CASH 200.00 / CHANGE 83.00`), so a
/// naive "largest number" pass picks the wrong figure without them.
const _totalNegatives = <String>[
  'subtotal',
  'sub total',
  'tax',
  'vat',
  'gst',
  'change',
  'cash',
  'tender',
  'paid',
  'due back',
  'savings',
  'discount',
];

/// Card fragments printed as `ending in 4242` or `**** 4242`.
///
/// Four digits next to a currency-formatted line is exactly the shape of a
/// plausible total, so these are excluded structurally rather than by keyword.
final RegExp _cardEndingPattern = RegExp(
  r'(ending\s+(in\s+)?\d{4}|[*x•]{2,}\s*\d{4}|\bx{4}\s*\d{4})',
  caseSensitive: false,
);

/// Currency symbols mapped to the ISO code the app uses.
const Map<String, String> _currencySymbols = {
  r'$': 'USD',
  '€': 'EUR',
  '£': 'GBP',
  '¥': 'JPY',
  '₹': 'INR',
  '₩': 'KRW',
  '₽': 'RUB',
};

/// ISO codes worth recognising when printed as text next to the total.
const _currencyCodes = <String>[
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'INR',
  'KRW',
  'RUB',
];

/// How far either side of the total line to look for a currency marker.
///
/// Deliberately narrow: a receipt can mention a currency in unrelated fine
/// print ("prices in USD where shown"), and taking that over the symbol beside
/// the actual figure would be worse than finding nothing.
const _currencyWindow = 2;

/// How far the item sum may drift from the stated total before it counts as a
/// disagreement.
///
/// Generous on purpose. Tax, tip, and service charges are frequently not
/// itemised, so a sum below the total is normal; only a real mismatch should
/// cost the user confidence.
const _itemSumTolerance = 0.02;

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
  final items = _extractLineItems(cleaned);
  final total = _resolveTotal(cleaned, items);
  final merchant = _extractMerchant(cleaned);
  final category = _guessCategory(merchant.value, cleaned);

  return ParsedReceipt(
    amount: total.value,
    amountConfidence: total.confidence,
    merchant: merchant.value,
    merchantConfidence: merchant.confidence,
    category: category.value,
    categoryConfidence: category.confidence,
    rawText: rawText,
    imagePath: imagePath,
    currencyCode: _detectCurrency(cleaned, total.lineIndex),
    lineItems: items,
    evidence: total.evidence,
    discrepancy: total.discrepancy,
  );
}

String _capped(String text) => text.length <= _maxRawTextChars
    ? text
    : '${text.substring(0, _maxRawTextChars)}…';

typedef _Guess<T> = ({T? value, FieldConfidence confidence});

// ------------------------------------------------------------------- amount

typedef _Total = ({
  double? value,
  FieldConfidence confidence,
  TotalEvidence evidence,
  ReceiptDiscrepancy? discrepancy,
  int? lineIndex,
});

/// True when a line must never be read as the total.
///
/// Applied before ranking *and* before the largest-number fallback, so an
/// excluded figure cannot win either path.
bool _isExcluded(String lower, String raw) =>
    _totalNegatives.any(lower.contains) || _cardEndingPattern.hasMatch(raw);

/// Picks the total, then tries to corroborate it.
///
/// Three signals are available on a typical receipt: a labelled line, the
/// arithmetic `cash - change`, and the sum of the item rows. Agreement between
/// any two is what earns high confidence; a keyword match on its own is only a
/// label, and labels get misread.
_Total _resolveTotal(List<String> lines, List<ReceiptLineItem> items) {
  final labelled = _labelledTotal(lines);
  final fromCash = _cashMinusChange(lines);
  final rawItemSum =
      items.isEmpty ? null : items.fold<double>(0, (sum, i) => sum + i.price);

  // A receipt that itemises its tax tells us exactly what the gap between the
  // items and the total should be. Without accounting for it, every receipt
  // carrying a tax line looks like an item-sum mismatch — the items genuinely
  // do not add up to the total, and are not meant to.
  final tax = _labelledValue(lines, const ['tax', 'vat', 'gst']);
  final itemSum =
      rawItemSum == null ? null : (tax == null ? rawItemSum : rawItemSum + tax);

  bool agrees(double? a, double? b) =>
      a != null && b != null && (a - b).abs() <= _itemSumTolerance;

  // ------------------------------------------------ a label was found
  if (labelled != null) {
    final value = labelled.value;

    if (agrees(value, fromCash) || agrees(value, itemSum)) {
      return (
        value: value,
        confidence: FieldConfidence.high,
        evidence: TotalEvidence.corroborated,
        discrepancy: null,
        lineIndex: labelled.index,
      );
    }

    // `cash - change` is arithmetic the receipt performed itself, so when it
    // contradicts the label it is the better of the two. The label is reported
    // rather than discarded — a user staring at the paper can settle it.
    if (fromCash != null) {
      return (
        value: fromCash,
        confidence: FieldConfidence.low,
        evidence: TotalEvidence.conflicting,
        discrepancy: CashChangeDiscrepancy(
          labelled: value,
          computed: fromCash,
        ),
        lineIndex: labelled.index,
      );
    }

    if (itemSum != null && !agrees(value, itemSum)) {
      // Tax and tip are routinely not itemised, so a total *above* the item sum
      // is ordinary and only mildly reduces confidence. Below the sum is not
      // explicable that way.
      final belowItems = value != null && value < itemSum - _itemSumTolerance;
      return (
        value: value,
        confidence: belowItems ? FieldConfidence.low : FieldConfidence.medium,
        evidence: TotalEvidence.conflicting,
        discrepancy: ItemSumDiscrepancy(labelled: value, itemSum: itemSum),
        lineIndex: labelled.index,
      );
    }

    return (
      value: value,
      confidence:
          labelled.onSameLine ? FieldConfidence.high : FieldConfidence.medium,
      evidence: TotalEvidence.labelledOnly,
      discrepancy: null,
      lineIndex: labelled.index,
    );
  }

  // ------------------------------------------- no label, but cash and change
  if (fromCash != null) {
    return (
      value: fromCash,
      confidence: agrees(fromCash, itemSum)
          ? FieldConfidence.high
          : FieldConfidence.medium,
      evidence: TotalEvidence.derivedFromCash,
      discrepancy: null,
      lineIndex: null,
    );
  }

  // ----------------------------------------------------- nothing but numbers
  // The largest money-shaped figure, with cash/change/card lines already
  // removed. A decent guess on a simple receipt and a poor one on a complex
  // bill, so it is marked low and the review screen asks for confirmation.
  double? largest;
  for (final line in lines) {
    if (_isExcluded(line.toLowerCase(), line)) continue;
    for (final match in _amountPattern.allMatches(line)) {
      final value = _toDouble(match.group(1));
      if (value == null) continue;
      if (largest == null || value > largest) largest = value;
    }
  }

  if (largest == null || largest <= 0) {
    return (
      value: null,
      confidence: FieldConfidence.none,
      evidence: TotalEvidence.guessed,
      discrepancy: null,
      lineIndex: null,
    );
  }

  return (
    value: largest,
    confidence: FieldConfidence.low,
    evidence: TotalEvidence.guessed,
    discrepancy: null,
    lineIndex: null,
  );
}

/// The best labelled total, by keyword tier then by position.
///
/// Within a tier the lowest line wins, which resolves
/// "Total 40.00 / Tip 6.00 / Total after tip 46.00" to 46.00.
({double? value, int index, bool onSameLine})? _labelledTotal(
  List<String> lines,
) {
  for (final tier in _totalKeywordTiers) {
    for (var i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();

      if (_isExcluded(lower, line)) continue;
      if (!tier.any(lower.contains)) continue;

      final onLine = _lastAmountIn(line);
      if (onLine != null) {
        return (value: onLine, index: i, onSameLine: true);
      }

      // Some layouts print the label and the figure on separate lines.
      if (i + 1 < lines.length) {
        final below = _lastAmountIn(lines[i + 1]);
        if (below != null) {
          return (value: below, index: i + 1, onSameLine: false);
        }
      }
    }
  }
  return null;
}

/// The figure on the lowest line matching any of [labels].
///
/// Used for tax and similar auxiliary lines. Deliberately does not reuse the
/// total exclusion list, since the whole point is to read a line that list
/// exists to reject.
double? _labelledValue(List<String> lines, List<String> labels) {
  for (var i = lines.length - 1; i >= 0; i--) {
    final lower = lines[i].toLowerCase();
    if (!labels.any(lower.contains)) continue;
    // "tax invoice" and "tax id" are headings, not amounts.
    if (lower.contains('invoice') || lower.contains('tax id')) continue;
    final value = _lastAmountIn(lines[i]);
    if (value != null) return value;
  }
  return null;
}

/// `cash - change`, when the receipt printed both.
///
/// This is the receipt doing the arithmetic for us, and it is independent of
/// however the total line was labelled or misread.
double? _cashMinusChange(List<String> lines) {
  double? cash;
  double? change;

  for (final line in lines) {
    final lower = line.toLowerCase();
    if (_cardEndingPattern.hasMatch(line)) continue;

    // "cash back" is money returned at the till, not the tender.
    if (cash == null &&
        lower.contains('cash') &&
        !lower.contains('cash back')) {
      cash = _lastAmountIn(line);
    }
    if (change == null &&
        (lower.contains('change') || lower.contains('due back'))) {
      change = _lastAmountIn(line);
    }
  }

  if (cash == null || change == null) return null;
  final total = cash - change;
  if (total <= 0) return null;
  return double.parse(total.toStringAsFixed(2));
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

// --------------------------------------------------------------- line items

/// A leading quantity, as `2 x Coffee` or `2x Coffee` or plain `2 Coffee`.
final RegExp _quantityPrefix = RegExp(r'^(\d{1,3})\s*[x×]?\s+(?=\D)');

/// Rows from the receipt body, as `description ... price`.
///
/// Conservative by design: a row only counts when it has text *and* a trailing
/// money figure, and is not a total, tax, or payment line. Over-collecting here
/// would poison the item-sum cross-check, which is worse than collecting
/// nothing — an absent sum simply means one fewer signal.
List<ReceiptLineItem> _extractLineItems(List<String> lines) {
  final items = <ReceiptLineItem>[];

  for (final line in lines) {
    final lower = line.toLowerCase();

    if (_isExcluded(lower, line)) continue;
    if (_allTotalKeywords.any(lower.contains)) continue;
    if (_phonePattern.hasMatch(line)) continue;
    if (_addressPattern.hasMatch(line)) continue;

    final price = _lastAmountIn(line);
    if (price == null || price <= 0) continue;

    // Strip the trailing figure to leave the description.
    final lastMatch = _amountPattern.allMatches(line).lastOrNull;
    if (lastMatch == null) continue;
    var description = line.substring(0, lastMatch.start).trim();

    int? quantity;
    final qty = _quantityPrefix.firstMatch(description);
    if (qty != null) {
      quantity = int.tryParse(qty.group(1)!);
      description = description.substring(qty.end).trim();
    }

    // A row with no words is a stray number, not an item.
    if (!_hasLetters.hasMatch(description)) continue;
    // Descriptions that are mostly digits are dates, till numbers, or barcodes.
    final letters = _hasLetters.allMatches(description).length;
    if (letters < description.length / 3) continue;

    items.add(ReceiptLineItem(
      description: _titleCase(description),
      price: price,
      quantity: quantity,
    ));
  }

  return items;
}

// ----------------------------------------------------------------- currency

/// The currency printed beside the total, or null when there is no signal.
///
/// Deliberately scoped to a window around the total line. A receipt may mention
/// a currency in unrelated fine print, and preferring that over the symbol next
/// to the actual figure would be worse than returning null — null lets the
/// caller fall back to the user's own currency, which is a better guess than
/// anything the parser can invent.
String? _detectCurrency(List<String> lines, int? totalLineIndex) {
  Iterable<String> window;
  if (totalLineIndex == null) {
    // No located total. The last few lines are where the payment block sits.
    window = lines.reversed.take(_currencyWindow * 2 + 1);
  } else {
    final from = (totalLineIndex - _currencyWindow).clamp(0, lines.length - 1);
    final to = (totalLineIndex + _currencyWindow).clamp(0, lines.length - 1);
    window = lines.sublist(from, to + 1);
  }

  for (final line in window) {
    for (final entry in _currencySymbols.entries) {
      if (line.contains(entry.key)) return entry.value;
    }
    final upper = line.toUpperCase();
    for (final code in _currencyCodes) {
      // Word-boundary match so "USDA ORGANIC" is not read as USD.
      if (RegExp('\\b$code\\b').hasMatch(upper)) return code;
    }
  }
  return null;
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
