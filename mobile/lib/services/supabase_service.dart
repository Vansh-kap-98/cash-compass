import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Build-time configuration.
///
/// Values come from `--dart-define-from-file=config/dev.json`, so nothing is
/// bundled as a readable asset. The anon key is public by design; this is
/// hygiene rather than secrecy.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Whether real auth is available.
  ///
  /// The app must boot and run without these — demo mode has to work on a
  /// fresh clone with no config, exactly as `isSupabaseConfigured` guaranteed
  /// on the web.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

/// Thin wrapper around Supabase initialisation.
abstract final class SupabaseService {
  static bool _ready = false;

  static bool get isReady => _ready;

  /// Initialises Supabase if configured. Safe to call unconditionally.
  static Future<void> init() async {
    if (!Env.isSupabaseConfigured) {
      debugPrint('Supabase not configured — demo mode only.');
      return;
    }
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // Supabase renamed this: `anonKey` is deprecated in favour of
        // `publishableKey`. Same value, new name.
        publishableKey: Env.supabaseAnonKey,
      );
      _ready = true;
    } catch (error) {
      // A bad URL or key must not prevent the app from starting; the user can
      // still work offline in demo mode.
      debugPrint('Supabase init failed: $error');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
