import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live USD-based exchange rates from frankfurter.app.
///
/// The endpoint needs no API key. Ported from the `fetch` call in
/// `CurrencyContext.tsx`.
class RatesApi {
  RatesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Every currency the source publishes, not a fixed shortlist.
  ///
  /// A receipt can be in any currency, and the app has to convert whatever it
  /// reads into the user's own. Asking for `to=INR,RUB` only served the three
  /// currencies the UI offers and left a euro receipt unconvertible.
  ///
  /// Note the host: `api.frankfurter.app` now 301-redirects here, and relying
  /// on a permanent redirect that the API owner can retire is not worth the
  /// saved character count.
  static final Uri _endpoint =
      Uri.parse('https://api.frankfurter.dev/v1/latest?from=USD');

  /// Secondary source, queried only for what the primary omits.
  ///
  /// Frankfurter republishes ECB reference rates, and **the ECB has not
  /// published a RUB reference rate since March 2022**. So a perfectly
  /// successful primary response simply has no RUB in it, and the app was
  /// quietly falling back to a hard-coded constant for one of the three
  /// currencies it offers — which is how RUB came to sit at 92 while the real
  /// rate was near 80, an error of roughly 14% on every rouble figure on
  /// screen.
  ///
  /// This source publishes RUB and needs no key. It is deliberately the
  /// fallback rather than the primary: the ECB set is the more authoritative
  /// for everything it does cover.
  static final Uri _supplementEndpoint =
      Uri.parse('https://open.er-api.com/v6/latest/USD');

  /// Fetches rates keyed by currency code, always including `USD: 1`.
  ///
  /// Throws on network or parse failure so the caller can decide whether to
  /// fall back to cached or static rates.
  Future<Map<String, double>> fetch() async {
    final response =
        await _client.get(_endpoint).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw http.ClientException(
        'Rates request failed with status ${response.statusCode}',
        _endpoint,
      );
    }

    final body = jsonDecode(response.body);
    if (body is! Map || body['rates'] is! Map) {
      throw const FormatException('Unexpected rates payload shape');
    }

    final rates = <String, double>{'USD': 1};
    _absorb(body['rates'], rates);

    // Fill only the gaps. If the primary already carried a currency, its value
    // stands — this call exists to supply RUB, not to second-guess the ECB.
    if (!rates.containsKey('RUB')) {
      await _absorbSupplement(rates);
    }

    return rates;
  }

  /// Merges a `{code: rate}` map into [into], skipping anything already there.
  void _absorb(Object? raw, Map<String, double> into) {
    if (raw is! Map) return;
    raw.forEach((key, value) {
      if (key is String && value is num && !into.containsKey(key)) {
        // Full precision, deliberately. The web app rounds rates to 2dp, which
        // is harmless at INR 83.5 but destroys currencies whose rate is below
        // one — BHD at 0.377 becomes 0.38, an 0.8% error on every conversion.
        // Same lesson as the storage-rounding bug in PARITY_SPEC.md §0: round
        // when a human reads the number, never before.
        final rate = value.toDouble();
        if (rate > 0 && rate.isFinite) into[key] = rate;
      }
    });
  }

  /// Best-effort top-up from the secondary source.
  ///
  /// Deliberately swallows its own failures: the primary response is already
  /// in hand, and losing the supplement should degrade RUB to the static
  /// fallback rather than fail the whole refresh and leave every currency
  /// stale.
  Future<void> _absorbSupplement(Map<String, double> into) async {
    try {
      final response = await _client
          .get(_supplementEndpoint)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body);
      if (body is Map) _absorb(body['rates'], into);
    } catch (_) {
      // Keep whatever the primary gave us.
    }
  }

  void dispose() => _client.close();
}
