import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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

  /// Signs in. Returns an error message, or null on success.
  Future<String?> signIn(String email, String password) async {
    if (!SupabaseService.isReady) {
      return 'Accounts are unavailable — this build has no Supabase config. '
          'Use demo mode.';
    }
    if (email.trim().isEmpty || password.isEmpty) {
      return 'Enter your email and password.';
    }
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on sb.AuthException catch (e) {
      return e.message;
    } catch (error) {
      debugPrint('Sign in failed: $error');
      return 'Could not sign in. Please try again.';
    }
  }

  /// Creates an account. Returns an error message, or null on success.
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) async {
    if (!SupabaseService.isReady) {
      return 'Accounts are unavailable — this build has no Supabase config. '
          'Use demo mode.';
    }

    final validation = validateSignUp(
      name: name,
      email: email,
      password: password,
      confirm: confirm,
    );
    if (validation != null) return validation;

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
          debugPrint('Profile upsert failed (non-fatal): $error');
        }
      }

      if (response.session == null) {
        return 'Check your email to confirm your account, then sign in.';
      }
      return null;
    } on sb.AuthException catch (e) {
      return e.message;
    } catch (error) {
      debugPrint('Sign up failed: $error');
      return 'Could not create the account. Please try again.';
    }
  }

  /// Shared validation so the form and the store can never disagree.
  static String? validateSignUp({
    required String name,
    required String email,
    required String password,
    required String confirm,
  }) {
    if (name.trim().isEmpty) return 'Enter your name.';
    if (!emailPattern.hasMatch(email.trim())) {
      return 'Enter a valid email address.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (password != confirm) return 'Passwords do not match.';
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
        debugPrint('Sign out failed: $error');
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
