import 'package:cash_compass/services/prefs.dart';
import 'package:cash_compass/state/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [Prefs] so the sign-in path can be exercised without a platform
/// channel.
class _FakePrefs implements Prefs {
  final Map<String, Object?> store = {};

  @override
  Future<bool?> getBool(String key) async => store[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => store[key] = value;

  @override
  Future<String?> getString(String key) async => store[key] as String?;

  @override
  Future<void> setString(String key, String value) async => store[key] = value;

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      store[key] as Map<String, dynamic>?;

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async =>
      store[key] = value;

  @override
  Future<List<dynamic>?> getJsonList(String key) async =>
      store[key] as List<dynamic>?;

  @override
  Future<void> setJsonList(String key, List<dynamic> value) async =>
      store[key] = value;

  @override
  Future<void> remove(String key) async => store.remove(key);

  @override
  Future<void> removeAll(Iterable<String> keys) async {
    for (final k in keys) {
      store.remove(k);
    }
  }
}

/// The built-in presentation account, and the flag that keeps it out of
/// ordinary builds.
///
/// It existed because with no Supabase project configured the sign-in form
/// could only ever fail. Real auth works now, so a hard-coded credential is a
/// fake auth path — it is compiled in only under
/// `--dart-define=ALLOW_DEMO_LOGIN=true`.
///
/// **These tests run with the flag off**, which is the shipping default, so
/// they assert the credentials are *rejected*. To check the enabled path:
///
///     flutter test --dart-define=ALLOW_DEMO_LOGIN=true \
///       test/auth_pilot_session_test.dart
///
/// which flips the expectation in the first test below — that is the point of
/// it, not a failure.
void main() {
  late _FakePrefs prefs;
  late AuthProvider auth;

  setUp(() async {
    prefs = _FakePrefs();
    auth = AuthProvider(prefs);
    await auth.load();
  });

  test('the flag decides whether the demo credentials are accepted', () async {
    final failure = await auth.signIn('pennypilots@gmail.com', '12345');

    if (kAllowDemoLogin) {
      expect(failure, isNull);
      expect(auth.isPilotSession, isTrue);
      expect(auth.user?.email, 'pennypilots@gmail.com');
    } else {
      expect(failure, isA<AuthErrorFailure>(),
          reason: 'with the flag off these are just a wrong password');
      expect((failure! as AuthErrorFailure).error, AuthError.noBackend);
      expect(auth.isPilotSession, isFalse);
      expect(auth.isSignedIn, isFalse);
    }
  });

  test(
    'the default build does not ship the bypass',
    () {
      expect(kAllowDemoLogin, isFalse,
          reason: 'a release built without the flag must reject the '
              'hard-coded credentials; if this fails, the default was changed');
    },
    // This one asserts the *default*, so a run that deliberately passes
    // --dart-define=ALLOW_DEMO_LOGIN=true skips it rather than reporting a
    // failure for doing exactly what it was asked.
    skip: kAllowDemoLogin
        ? 'ALLOW_DEMO_LOGIN was set for this run; nothing to assert'
        : null,
  );

  test('a wrong password is rejected either way', () async {
    final failure = await auth.signIn('pennypilots@gmail.com', 'wrong');

    expect(failure, isA<AuthErrorFailure>());
    expect((failure! as AuthErrorFailure).error, AuthError.noBackend);
    expect(auth.isPilotSession, isFalse);
  });

  test('an empty form reports missing credentials, not a backend error',
      () async {
    final failure = await auth.signIn('', '');
    expect((failure! as AuthErrorFailure).error, AuthError.missingCredentials);
  });

  test('signing out clears the session, on this run and the next', () async {
    // Nothing to sign out of without a backend, but the stored flag must not
    // survive: a stale pilotSession key would sign the next launch straight in.
    await auth.signOut();

    expect(auth.isSignedIn, isFalse);
    expect(prefs.store[PrefsKeys.pilotSession], isFalse);

    final restarted = AuthProvider(prefs);
    await restarted.load();
    expect(restarted.isSignedIn, isFalse);
  });
}
