import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dev/log.dart';
import 'app_colors.dart';

/// One family, one scale.
///
/// The old theme paired a heading face with a body face and let Settings swap
/// in two more packs. This design uses a single geometric sans across display
/// and body, and separates the two roles by weight and size instead.
abstract final class AppTypography {
  /// Manrope — geometric-leaning sans, weights 200-800.
  ///
  /// Chosen over the more obviously geometric Outfit and Poppins for one
  /// non-negotiable reason: **it has Cyrillic**, and those do not. The app
  /// ships in Russian, and a family without Cyrillic silently renders every
  /// Russian string in a system fallback — which is what the previous heading
  /// font (Outfit) was already doing.
  ///
  /// Also narrower than Montserrat, the other Cyrillic-capable geometric
  /// candidate. That matters here: Russian runs materially longer than English
  /// and the workspace cards have fixed heights, so width is a real constraint
  /// rather than a taste question.
  static const family = 'Manrope';

  /// Screen titles and the balance figure. One per screen at most.
  static const displaySize = 34.0;

  /// Card and section headings.
  static const headerSize = 18.0;

  /// Default reading size.
  static const bodySize = 15.0;

  /// Metadata, list subtitles, helper text.
  static const captionSize = 13.0;

  /// [GoogleFonts.getTextTheme], degrading to [base] if the family is unknown.
  ///
  /// A font is decoration and must never be able to take down the widget tree.
  /// `google_fonts` throws on an unrecognised family, and that throw happens
  /// while building [ThemeData] — which `MaterialApp` reads on every build — so
  /// one bad name previously blanked the whole screen. Falling back mirrors
  /// what a CSS font stack does anyway.
  static TextTheme _safe(String name, TextTheme base) {
    try {
      return GoogleFonts.getTextTheme(name, base);
    } catch (error) {
      logError('Font family "$name"', error);
      return base;
    }
  }

  /// The full text theme.
  ///
  /// Sizes are explicit rather than inherited from Material's defaults. The
  /// Settings text-size slider and the OS accessibility scale both apply at
  /// paint time through `MediaQuery.textScaler` (see `main.dart`), so naming a
  /// size here does not fight either of them — it just makes the scale legible
  /// in one place instead of spread across Material's defaults.
  ///
  /// [fontFamily] exists so a test can drive the missing-family path; the app
  /// always uses the default.
  static TextTheme textTheme({String fontFamily = family}) =>
      _safe(fontFamily, const TextTheme()).merge(scale());

  /// The size, weight and colour ramp, with no family attached.
  ///
  /// Split out from [textTheme] so it can be read without touching
  /// `google_fonts` — which starts a network fetch on first use, and so cannot
  /// be called from a plain unit test without leaking async work past the end
  /// of it.
  ///
  /// [textTheme] layers this *over* the family with `merge` rather than
  /// `copyWith`. That distinction matters: `copyWith` replaces a slot outright,
  /// which would drop the `fontFamily` the base carries and silently render the
  /// whole app in the platform default.
  static TextTheme scale() {
    const ink = AppColors.ink;
    const secondary = AppColors.inkSecondary;

    return const TextTheme(
      // Display — the one large figure on a screen.
      displayLarge: TextStyle(
        fontSize: displaySize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.18,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.2,
        color: ink,
      ),

      // Headline — screen titles in the app bar.
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: headerSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: ink,
      ),

      // Title — card and section headings.
      titleLarge: TextStyle(
        fontSize: headerSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: ink,
      ),

      // Body.
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontSize: bodySize,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontSize: captionSize,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: secondary,
      ),

      // Labels — buttons, chips, field labels.
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontSize: captionSize,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: secondary,
      ),
    );
  }
}
