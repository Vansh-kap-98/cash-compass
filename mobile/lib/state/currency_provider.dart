import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/json_utils.dart';
import '../services/prefs.dart';
import '../services/rates_api.dart';

/// The three currencies the app supports, in cycle order.
enum AppCurrency {
  usd('USD', r'$', 'en_US'),
  inr('INR', '₹', 'en_IN'),
  rub('RUB', '₽', 'ru_RU');

  const AppCurrency(this.code, this.symbol, this.locale);

  final String code;
  final String symbol;

  /// Locale used for grouping rules — `en_IN` gives lakh grouping
  /// (₹1,23,456.78) and `ru_RU` gives `1 234,56 ₽`.
  final String locale;

  static AppCurrency fromCode(String? code) {
    for (final c in AppCurrency.values) {
      if (c.code == code) return c;
    }
    return AppCurrency.usd;
  }
}

/// Rates used when the network is unavailable and nothing is cached.
/// Same values as the web app's fallback.
const Map<String, double> _fallbackRates = {'USD': 1, 'INR': 83.5, 'RUB': 92};

/// How long a cached rate set stays valid.
const Duration _cacheTtl = Duration(hours: 1);

/// Holds the active display currency and the USD-based conversion rates.
///
/// Port of `frontend/src/contexts/CurrencyContext.tsx`. All stored amounts are
/// USD; this class converts at the display boundary in both directions.
class CurrencyProvider extends ChangeNotifier {
  CurrencyProvider(this._prefs, {RatesApi? api})
      : _api = api ?? RatesApi();

  final Prefs _prefs;
  final RatesApi _api;

  AppCurrency currency = AppCurrency.usd;
  Map<String, double> rates = Map.of(_fallbackRates);

  bool ratesLoading = false;
  String? ratesError;
  DateTime? lastUpdated;

  bool loaded = false;

  double get _rate => rates[currency.code] ?? 1;

  // ------------------------------------------------------------------ load

  Future<void> load() async {
    currency = AppCurrency.fromCode(await _prefs.getString(PrefsKeys.currency));

    final cached = await _prefs.getJson(PrefsKeys.exchangeRates);
    if (cached != null) {
      final timestamp = asNullableDouble(cached['timestamp']);
      final rawRates = cached['rates'];
      if (timestamp != null && rawRates is Map) {
        final cachedAt =
            DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
        if (DateTime.now().difference(cachedAt) < _cacheTtl) {
          rates = _coerceRates(rawRates);
          lastUpdated = cachedAt;
        }
      }
    }

    loaded = true;
    notifyListeners();

    // Only hit the network if the cache was missing or stale.
    if (lastUpdated == null) {
      await refreshRates();
    }
  }

  Map<String, double> _coerceRates(Map<dynamic, dynamic> raw) {
    final result = Map<String, double>.of(_fallbackRates);
    raw.forEach((key, value) {
      if (key is String) {
        final parsed = asNullableDouble(value);
        if (parsed != null && parsed > 0) result[key] = parsed;
      }
    });
    return result;
  }

  /// Fetches fresh rates, keeping the previous set on failure so the UI never
  /// falls back to wrong numbers mid-session.
  Future<void> refreshRates() async {
    if (ratesLoading) return;
    ratesLoading = true;
    ratesError = null;
    notifyListeners();

    try {
      final fresh = await _api.fetch();
      // Merge onto the fallbacks rather than replacing them. Frankfurter tracks
      // ECB reference rates, and the ECB no longer publishes RUB — so a
      // successful response can legitimately omit a currency we still support.
      // Replacing wholesale would drop RUB and silently convert it at 1:1.
      rates = {..._fallbackRates, ...fresh};
      lastUpdated = DateTime.now();
      await _prefs.setJson(PrefsKeys.exchangeRates, {
        'rates': rates,
        'timestamp': lastUpdated!.millisecondsSinceEpoch,
      });
    } catch (error) {
      ratesError = 'Live rates unavailable — using saved rates.';
      debugPrint('Rate refresh failed: $error');
    } finally {
      ratesLoading = false;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------- currency

  Future<void> setCurrency(AppCurrency next) async {
    if (next == currency) return;
    currency = next;
    notifyListeners();
    await _prefs.setString(PrefsKeys.currency, next.code);
  }

  /// Advances to the next currency in [AppCurrency.values], wrapping around.
  /// This backs the tappable currency chip that replaces the desktop-only
  /// Right-Ctrl shortcut.
  Future<void> cycleCurrency() {
    final next = AppCurrency
        .values[(currency.index + 1) % AppCurrency.values.length];
    return setCurrency(next);
  }

  // ------------------------------------------------------------ conversion

  /// USD -> active currency.
  double convertFromUsd(double amount) {
    if (!amount.isFinite) return 0;
    return double.parse((amount * _rate).toStringAsFixed(2));
  }

  /// Active currency -> USD. Use this on every amount the user types.
  double convertToUsd(double amount) {
    if (!amount.isFinite || _rate == 0) return 0;
    return double.parse((amount / _rate).toStringAsFixed(2));
  }

  /// Formats an amount already expressed in the active currency.
  String formatAmount(double amount, {int? decimalDigits}) {
    final format = NumberFormat.currency(
      locale: currency.locale,
      symbol: currency.symbol,
      decimalDigits: decimalDigits ?? 2,
    );
    return format.format(amount);
  }

  /// Converts from USD and formats in one step — the common case for anything
  /// read out of [FinanceProvider].
  String formatFromUsd(double usdAmount, {int? decimalDigits}) =>
      formatAmount(convertFromUsd(usdAmount), decimalDigits: decimalDigits);

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}
