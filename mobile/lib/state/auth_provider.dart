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
    this.isDemo = false,
  });

  final String id;
  final String email;
  final String? name;
  final bool isDemo;

  String get displayName => name?.trim().isNotEmpty == true ? name! : email;
}

const _demoUser = AppUser(
  id: 'demo-user',
  email: 'demo@cashcompass.app',
  name: 'Demo',
  isDemo: true,
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

/// Session state: real Supabase auth plus a local demo bypass.
///
/// Port of `AuthContext.tsx`. Demo mode exists so the app is fully usable with
/// no backend configured — important both for development and because none of
/// the finance data is server-side anyway.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._prefs);

  final Prefs _prefs;

  AppUser? _authUser;
  bool _isDemoMode = false;
  bool loading = true;

  StreamSubscription<sb.AuthState>? _authSub;

  /// The effective user, demo or real.
  AppUser? get user => _isDemoMode ? _demoUser : _authUser;

  bool get isDemoMode => _isDemoMode;
  bool get isSignedIn => user != null;
  bool get canUseSupabase => SupabaseService.isReady;

  Future<void> load() async {
    _isDemoMode = (await _prefs.getBool(PrefsKeys.demoMode)) ?? false;

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
    if (!SupabaseService.isReady) {
      return const AuthErrorFailure(AuthError.noBackend);
    }
    if (email.trim().isEmpty || password.isEmpty) {
      return const AuthErrorFailure(AuthError.missingCredentials);
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

      final created = response.user;
      if (created != null) {
        // Best-effort profile row, matching the web app. Nothing reads this
        // table yet, so a failure here must not block sign-up.
        try {
          await SupabaseService.client.from('profiles').upsert({
            'id': created.id,
            'name': name.trim(),
            'email': email.trim(),
          }, onConflict: 'id');
        } catch (error) {
          logError('Profile upsert (non-fatal)', error);
        }
      }

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

  /// Enters demo mode.
  ///
  /// The caller is responsible for clearing finance data — this store has no
  /// business reaching into the others.
  Future<void> enableDemoMode() async {
    _isDemoMode = true;
    loading = false;
    notifyListeners();
    await _prefs.setBool(PrefsKeys.demoMode, true);
  }

  Future<void> disableDemoMode() async {
    _isDemoMode = false;
    notifyListeners();
    await _prefs.setBool(PrefsKeys.demoMode, false);
  }

  Future<void> signOut() async {
    await disableDemoMode();
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
