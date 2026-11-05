import 'dart:convert';

import 'package:cash_compass/services/rates_api.dart';
import 'package:cash_compass/state/currency_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Serves canned bodies per host so the two-source merge can be tested without
/// the network.
class _FakeClient extends http.BaseClient {
  _FakeClient(this.bodies);

  /// host fragment -> (status, body)
  final Map<String, List<Object>> bodies;
  final List<String> calls = [];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final url = request.url.toString();
    calls.add(url);
    for (final entry in bodies.entries) {
      if (url.contains(entry.key)) {
        final status = entry.value[0] as int;
        final body = entry.value[1] as String;
        return http.StreamedResponse(Stream.value(utf8.encode(body)), status);
      }
    }
    return http.StreamedResponse(Stream.value(utf8.encode('{}')), 404);
  }
}

const _frankfurterNoRub = '{"base":"USD","rates":{"INR":95.07,"EUR":0.86}}';
const _supplement =
    '{"result":"success","rates":{"RUB":80.41,"INR":94.0,"EUR":0.9}}';

/// Guards the rouble.
///
/// Frankfurter republishes ECB reference rates and the ECB has not published a
/// RUB rate since March 2022, so a completely successful primary response
/// simply has no RUB in it. Before this, the app silently fell back to a
/// hard-coded 92 while the real rate was near 80 — roughly 14% wrong on every
/// rouble figure, and invisible because nothing ever reported it as stale.
void main() {
  test('RUB is fetched from the supplement when the primary omits it',
      () async {
    final client = _FakeClient({
      'frankfurter': [200, _frankfurterNoRub],
      'er-api': [200, _supplement],
    });

    final rates = await RatesApi(client: client).fetch();

    expect(rates['RUB'], closeTo(80.41, 0.001),
        reason: 'the whole point of the second source');
    expect(client.calls.length, 2);
  });

  test('the primary wins wherever both publish a rate', () async {
    final client = _FakeClient({
      'frankfurter': [200, _frankfurterNoRub],
      'er-api': [200, _supplement],
    });

    final rates = await RatesApi(client: client).fetch();

    expect(rates['INR'], closeTo(95.07, 0.001),
        reason: 'ECB figure must not be overwritten by the supplement 94.0');
    expect(rates['EUR'], closeTo(0.86, 0.001));
  });

  test('the supplement is not called when the primary already has RUB',
      () async {
    final client = _FakeClient({
      'frankfurter': [200, '{"rates":{"INR":95.07,"RUB":79.5}}'],
      'er-api': [200, _supplement],
    });

    final rates = await RatesApi(client: client).fetch();

    expect(rates['RUB'], closeTo(79.5, 0.001));
    expect(client.calls.length, 1,
        reason: 'no second request when there is nothing to fill in');
  });

  test('a failing supplement leaves the primary intact', () async {
    final client = _FakeClient({
      'frankfurter': [200, _frankfurterNoRub],
      'er-api': [500, 'upstream down'],
    });

    final rates = await RatesApi(client: client).fetch();

    expect(rates['INR'], closeTo(95.07, 0.001),
        reason: 'losing the supplement must not fail the whole refresh');
    expect(rates.containsKey('RUB'), isFalse,
        reason: 'absent here, so the provider falls back to kFallbackRates');
  });

  test('USD is always present and is always 1', () async {
    final client = _FakeClient({
      'frankfurter': [200, _frankfurterNoRub],
    });
    final rates = await RatesApi(client: client).fetch();
    expect(rates['USD'], 1);
  });

  test('the static fallback carries a plausible rouble rate', () {
    // The failure this guards is a constant drifting for years unnoticed.
    // 92 sat in the binary long after the real rate left the band it was
    // written for.
    final rub = kFallbackRates['RUB']!;
    expect(rub, greaterThan(50));
    expect(rub, lessThan(130));
    expect(kFallbackRates['INR']!, greaterThan(70));
    expect(kFallbackRates['USD'], 1);
  });
}
