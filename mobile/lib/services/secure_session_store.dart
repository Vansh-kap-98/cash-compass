import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dev/log.dart';

/// Persists the Supabase auth session in the Android Keystore.
///
/// The default [LocalStorage] supabase_flutter installs is
/// `SharedPreferencesLocalStorage`, which writes the session JSON — access
/// token, refresh token, and user record — as plaintext into the app's
/// `shared_prefs` XML. That file is readable on a rooted device and is included
/// in an unencrypted `adb backup`, so the refresh token in it is replayable by
/// anyone who gets the file. `flutter_secure_storage` puts it behind
/// `EncryptedSharedPreferences`, keyed by the hardware-backed Keystore.
///
/// The session is a single opaque string as far as this class is concerned; it
/// is never parsed or logged here.
class SecureSessionStore extends LocalStorage {
  SecureSessionStore({required this.supabaseUrl});

  /// Used only to reproduce the key that the old plaintext storage wrote to,
  /// so the stale copy can be deleted. See [_purgeLegacyPlaintextSession].
  final String supabaseUrl;

  static const _key = 'supabase-session';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> initialize() async {
    await _purgeLegacyPlaintextSession();
  }

  /// Deletes any session left behind by a build that used SharedPreferences.
  ///
  /// Without this the old plaintext token simply stays on disk after the
  /// upgrade — still valid, still replayable — which would defeat the point of
  /// moving to the Keystore. It is deleted rather than migrated: a re-login
  /// costs the user one screen, and copying a token that has already been
  /// sitting in a world-backupable file treats it as trustworthy when it is
  /// not.
  Future<void> _purgeLegacyPlaintextSession() async {
    try {
      final host = Uri.parse(supabaseUrl).host.split('.').first;
      final prefs = await SharedPreferences.getInstance();
      final legacyKey = 'sb-$host-auth-token';
      if (prefs.containsKey(legacyKey)) {
        await prefs.remove(legacyKey);
        logDebug(() => 'Removed legacy plaintext session from SharedPreferences');
      }
    } catch (error) {
      // Never block startup over cleanup of a key that may not exist.
      logError('Legacy session purge', error);
    }
  }

  @override
  Future<bool> hasAccessToken() async {
    try {
      return await _storage.containsKey(key: _key);
    } catch (error) {
      logError('Session read', error);
      return false;
    }
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _key);
    } catch (error) {
      // A Keystore read can fail after a device restore, when the key material
      // no longer matches the ciphertext. Treat it as "no session" so the app
      // shows the sign-in screen rather than crashing on launch.
      logError('Session read', error);
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _storage.write(key: _key, value: persistSessionString);
    } catch (error) {
      logError('Session write', error);
    }
  }

  @override
  Future<void> removePersistedSession() async {
    try {
      await _storage.delete(key: _key);
    } catch (error) {
      logError('Session delete', error);
    }
  }
}
