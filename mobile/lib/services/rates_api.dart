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
    (body['rates'] as Map).forEach((key, value) {
      if (key is String && value is num) {
        // Full precision, deliberately. The web app rounds rates to 2dp, which
        // is harmless at INR 83.5 but destroys currencies whose rate is below
        // one — BHD at 0.377 becomes 0.38, an 0.8% error on every conversion.
        // Same lesson as the storage-rounding bug in PARITY_SPEC.md §0: round
        // when a human reads the number, never before.
        final rate = value.toDouble();
        if (rate > 0 && rate.isFinite) rates[key] = rate;
      }
    });

    return rates;
  }

  void dispose() => _client.close();
}
