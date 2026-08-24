import 'dart:convert';

import 'package:http/http.dart' as http;

/// Live USD-based exchange rates from frankfurter.app.
///
/// The endpoint needs no API key. Ported from the `fetch` call in
/// `CurrencyContext.tsx`.
class RatesApi {
  RatesApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _endpoint =
      Uri.parse('https://api.frankfurter.app/latest?from=USD&to=INR,RUB');

  /// Fetches rates keyed by currency code, always including `USD: 1`.
  ///
  /// Throws on network or parse failure so the caller can decide whether to
  /// fall back to cached or static rates.
  Future<Map<String, double>> fetch() async {
    final response = await _client
        .get(_endpoint)
        .timeout(const Duration(seconds: 10));

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
        // The web app rounds to 2dp; match it so converted amounts agree.
        rates[key] = double.parse(value.toDouble().toStringAsFixed(2));
      }
    });

    return rates;
  }

  void dispose() => _client.close();
}
