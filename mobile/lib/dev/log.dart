import 'package:flutter/foundation.dart';

/// Debug-only logging.
///
/// `debugPrint` is **not** stripped from release builds — it forwards to
/// `print`, and anything it emits is readable through `adb logcat` on any
/// device with USB debugging on. For a finance app that means transaction
/// amounts, merchant names, session tokens, and email addresses are one cable
/// away from a bystander unless every call site is guarded.
///
/// Guarding 20-odd call sites individually is easy to get wrong once and never
/// notice, so the guard lives here instead. In release, `kDebugMode` is a
/// compile-time `false` and the whole body is tree-shaken away.
///
/// The message is taken as a closure so the interpolation itself — which may
/// concatenate the very data we are trying not to leak — never runs in release
/// either.
void logDebug(String Function() message) {
  if (!kDebugMode) return;
  debugPrint(message());
}

/// Logs a failure without echoing whatever payload caused it.
///
/// Exception `toString()` is not safe to log verbatim here: `FormatException`
/// includes a slice of the source it failed on, which for this app is the
/// stored finance JSON, and Supabase's `AuthException` carries the email
/// address that was being signed in. Recording the type plus a caller-supplied
/// label keeps the diagnostic value — you still learn *what* broke and *where*
/// — without the contents.
void logError(String context, Object error) {
  if (!kDebugMode) return;
  debugPrint('$context failed: ${error.runtimeType}');
}
