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

/// The built-in presentation account.
///
/// Exists so the sign-in screen can be demonstrated during the team defense:
/// with no Supabase project configured, every real credential returns
/// `noBackend`, so without this the form could only ever fail on stage.
void main() {
  late _FakePrefs prefs;
  late AuthProvider auth;

  setUp(() async {
    prefs = _FakePrefs();
    auth = AuthProvider(prefs);
    await auth.load();
  });

  test('the presentation credentials sign in with no backend configured', () async {
    final failure = await auth.signIn('pennypilots@gmail.com', '12345');

    expect(failure, isNull, reason: 'these credentials must bypass Supabase');
    expect(auth.isSignedIn, isTrue);
    expect(auth.isPilotSession, isTrue);
    expect(auth.user?.email, 'pennypilots@gmail.com');
    expect(auth.user?.isDemo, isFalse,
        reason: 'this is a signed-in account, not demo mode');
  });

  test('the email is matched case-insensitively and trimmed', () async {
    final failure = await auth.signIn('  PennyPilots@Gmail.com  ', '12345');
    expect(failure, isNull);
    expect(auth.isPilotSession, isTrue);
  });

  test('a wrong password does not sign in', () async {
    final failure = await auth.signIn('pennypilots@gmail.com', 'wrong');

    expect(failure, isA<AuthErrorFailure>());
    expect((failure! as AuthErrorFailure).error, AuthError.noBackend,
        reason: 'it should fall through to the normal path, not be accepted');
    expect(auth.isPilotSession, isFalse);
  });

  test('an empty form still reports missing credentials', () async {
    final failure = await auth.signIn('', '');
    expect((failure! as AuthErrorFailure).error, AuthError.missingCredentials);
  });

  test('the session survives a restart', () async {
    await auth.signIn('pennypilots@gmail.com', '12345');
    expect(prefs.store[PrefsKeys.pilotSession], isTrue);

    final restarted = AuthProvider(prefs);
    await restarted.load();

    expect(restarted.isSignedIn, isTrue,
        reason: 'backgrounding the app mid-demo must not sign the user out');
    expect(restarted.user?.email, 'pennypilots@gmail.com');
  });

  test('signing out clears it, on this run and the next', () async {
    await auth.signIn('pennypilots@gmail.com', '12345');
    await auth.signOut();

    expect(auth.isSignedIn, isFalse);
    expect(auth.isPilotSession, isFalse);

    final restarted = AuthProvider(prefs);
    await restarted.load();
    expect(restarted.isSignedIn, isFalse);
  });

  test('entering demo mode replaces the presentation session', () async {
    await auth.signIn('pennypilots@gmail.com', '12345');
    await auth.enableDemoMode();

    expect(auth.isDemoMode, isTrue);
    expect(auth.isPilotSession, isFalse,
        reason: 'the two must never both be live, or `user` is ambiguous');
    expect(auth.user?.isDemo, isTrue);
  });
}
