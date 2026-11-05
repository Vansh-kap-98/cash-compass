import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../dev/log.dart';
import '../services/prefs.dart';
import '../services/supabase_service.dart';

/// Who is currently using the app.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.name,
  });

  final String id;
  final String email;
  final String? name;

  String get displayName => name?.trim().isNotEmpty == true ? name! : email;
}

/// The built-in presentation account.
///
/// Signing in with these credentials enters the app without a backend, so the
/// sign-in screen can be shown and used during the team defense — with no
/// Supabase project configured, the real path can only ever return
/// [AuthError.noBackend].
///
/// **Off by default.** Now that real Supabase auth works, a hard-coded
/// credential is a fake auth path, so it is behind a build flag rather than
/// compiled into every binary:
///
///     flutter build apk --dart-define=ALLOW_DEMO_LOGIN=true
///
/// Builds without that flag reject these credentials like any other wrong
/// password. Use it for the team defense build; never for a real release.
///
/// **These credentials are not a secret.** In a build that enables them,
/// anyone who unpacks the APK can read them — which is the other reason they
/// stay off unless deliberately switched on.
const kAllowDemoLogin =
    bool.fromEnvironment('ALLOW_DEMO_LOGIN');

const _pilotEmail = 'pennypilots@gmail.com';
const _pilotPassword = '12345';

const _pilotUser = AppUser(
  id: 'penny-pilots',
  email: _pilotEmail,
  name: 'Penny Pilots',
);

/// Why a sign-in or sign-up attempt failed.
///
/// Returned instead of a sentence so the form can render it in the active
/// language — see `lib/l10n/presenters.dart`.
enum AuthError {
  noBackend,
  missingCredentials,
  signInFailed,
  signUpFailed,
  confirmEmail,
  missingName,
  invalidEmail,
  shortPassword,
  passwordMismatch,
}

/// The outcome of an auth attempt: one of this app's own [AuthError] cases, or
/// a message Supabase itself produced.
///
/// Supabase returns its own already-worded English strings ("Invalid login
/// credentials"), which cannot be translated here without matching on their
/// text — brittle, and it changes between releases. Those are passed through
/// verbatim and shown as-is; everything this app decides for itself is an
/// [AuthError] and gets translated.
sealed class AuthFailure {
  const AuthFailure();
}

class AuthErrorFailure extends AuthFailure {
  const AuthErrorFailure(this.error);
  final AuthError error;
}

class AuthServerFailure extends AuthFailure {
  const AuthServerFailure(this.message);
  final String message;
}

/// Session state, backed by Supabase auth.
///
/// Demo mode was removed once real auth worked: it let the app be used with no
/// backend configured, which is exactly the fake data path that hides a broken
/// sign-in.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._prefs);

  final Prefs _prefs;

  AppUser? _authUser;
  bool _isPilotSession = false;
  bool loading = true;

  StreamSubscription<sb.AuthState>? _authSub;

  /// The effective user: the built-in presentation account, or the real one.
  AppUser? get user => _isPilotSession ? _pilotUser : _authUser;

  /// True while the built-in presentation account is signed in.
  bool get isPilotSession => _isPilotSession;

  bool get isSignedIn => user != null;
  bool get canUseSupabase => SupabaseService.isReady;

  Future<void> load() async {
    _isPilotSession = (await _prefs.getBool(PrefsKeys.pilotSession)) ?? false;

    if (SupabaseService.isReady) {
      final session = SupabaseService.client.auth.currentSession;
      _authUser = _fromSession(session?.user);

      _authSub = SupabaseService.client.auth.onAuthStateChange.listen((state) {
        _authUser = _fromSession(state.session?.user);
        notifyListeners();
      });
    }

    loading = false;
    notifyListeners();
  }

  AppUser? _fromSession(sb.User? u) {
    if (u == null) return null;
    return AppUser(
      id: u.id,
      email: u.email ?? '',
      name: u.userMetadata?['full_name'] as String?,
    );
  }

  // --------------------------------------------------------------- actions

  /// Signs in. Returns the failure, or null on success.
  Future<AuthFailure?> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthErrorFailure(AuthError.missingCredentials);
    }

    // Checked before the backend test, not after: when Supabase is not
    // configured the branch below returns `noBackend` unconditionally, so a
    // check placed after it would never run.
    if (kAllowDemoLogin &&
        email.trim().toLowerCase() == _pilotEmail &&
        password == _pilotPassword) {
      _isPilotSession = true;
      loading = false;
      notifyListeners();
      await _prefs.setBool(PrefsKeys.pilotSession, true);
      return null;
    }

    if (!SupabaseService.isReady) {
      return const AuthErrorFailure(AuthError.noBackend);
    }
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on sb.AuthException catch (e) {
      return AuthServerFailure(e.message);
    } catch (error) {
      logError('Sign in', error);
      return const AuthErrorFailure(AuthError.signInFailed);
    }
  }

  /// Creates an account. Returns the failure, or null on success.
  Future<AuthFailure?> signUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    if (!SupabaseService.isReady) {
      return const AuthErrorFailure(AuthError.noBackend);
    }

    final validation = validateSignUp(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
    );
    if (validation != null) return AuthErrorFailure(validation);

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim(), 'display_name': name.trim()},
      );

      // The display name is saved on the auth user by the call above, through
      // `data: {'full_name': ...}`, which is where the UI reads it from.
      //
      // A best-effort `profiles` upsert used to sit here. There is no
      // `public.profiles` table in this project, so it failed on every
      // sign-up -- harmlessly, because it was logged rather than returned,
      // but it still cost a round trip and wrote a misleading error to the
      // log. The web app had the same upsert *unguarded*, where it broke
      // sign-up outright. Nothing reads the table, so both are gone.

      if (response.session == null) {
        return const AuthErrorFailure(AuthError.confirmEmail);
      }
      return null;
    } on sb.AuthException catch (e) {
      return AuthServerFailure(e.message);
    } catch (error) {
      logError('Sign up', error);
      return const AuthErrorFailure(AuthError.signUpFailed);
    }
  }

  /// Shared validation so the form and the store can never disagree.
  static AuthError? validateSignUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) {
    if (name.trim().isEmpty) return AuthError.missingName;
    if (!emailPattern.hasMatch(email.trim())) {
      return AuthError.invalidEmail;
    }
    if (password.length < 8) {
      return AuthError.shortPassword;
    }
    if (password != confirm) return AuthError.passwordMismatch;
    return null;
  }

  static final RegExp emailPattern =
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$', caseSensitive: false);

  Future<void> signOut() async {
    _isPilotSession = false;
    await _prefs.setBool(PrefsKeys.pilotSession, false);
    if (SupabaseService.isReady) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (error) {
        logError('Sign out', error);
      }
    }
    _authUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
