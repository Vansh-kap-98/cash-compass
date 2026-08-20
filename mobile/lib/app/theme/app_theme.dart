import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../state/theme_provider.dart';
import 'app_tokens.dart';

/// Turns a set of [AppTokens] into the [ThemeData] the whole app reads through
/// `Theme.of(context)`.
///
/// Everything colour- or radius-related must come from here rather than from
/// literals in widgets. That is the Flutter equivalent of the CSS-variable
/// discipline the web app already keeps, and it is what makes dropping in the
/// other four themes later a one-line change.
///
/// [fontPack] and [fontSizeFactor] come from the Settings controls; the pack
/// overrides the theme's own font choices when the user picks a non-default one.
ThemeData buildTheme(
  AppTokens t, {
  FontPack fontPack = FontPack.defaultPack,
  double fontSizeFactor = 1.0,
}) {
  // Dragging the text-size slider notifies on every tick, and each notify
  // rebuilds MaterialApp — which would rebuild the whole Google Fonts text
  // theme (15+ TextStyles) 60 times a second. Memoising makes a repeat call a
  // map lookup. The key space is tiny: 5 themes x 3 font packs x 8 slider
  // stops, and only the combinations actually visited are ever built.
  final key = '${t.name}|${fontPack.id}|${fontSizeFactor.toStringAsFixed(2)}';
  final cached = _themeCache[key];
  if (cached != null) return cached;

  final built = _buildTheme(t, fontPack, fontSizeFactor);
  _themeCache[key] = built;
  return built;
}

final Map<String, ThemeData> _themeCache = {};

ThemeData _buildTheme(
  AppTokens t,
  FontPack fontPack,
  double fontSizeFactor,
) {
  final scheme = ColorScheme(
    brightness: ThemeData.estimateBrightnessForColor(t.background),
    primary: t.primary,
    onPrimary: t.primaryForeground,
    secondary: t.secondary,
    onSecondary: t.secondaryForeground,
    error: t.destructive,
    onError: t.destructiveForeground,
    surface: t.card,
    onSurface: t.cardForeground,
    surfaceContainerHighest: t.muted,
    onSurfaceVariant: t.mutedForeground,
    outline: t.border,
    outlineVariant: t.input,
  );

  // A non-default font pack overrides the theme's own font choices.
  final bodyFamily = fontPack == FontPack.defaultPack
      ? t.bodyFont
      : fontPack.bodyFont;
  final headingFamily = fontPack == FontPack.defaultPack
      ? t.headingFont
      : fontPack.headingFont;

  final baseText = GoogleFonts.getTextTheme(bodyFamily)
      .apply(
        bodyColor: t.foreground,
        displayColor: t.foreground,
        fontSizeFactor: fontSizeFactor,
      );

  // Headings use the heading font; body styles keep the body font.
  final headingStyle = GoogleFonts.getFont(headingFamily, color: t.foreground);
  final textTheme = baseText.copyWith(
    displayLarge: baseText.displayLarge?.merge(headingStyle),
    displayMedium: baseText.displayMedium?.merge(headingStyle),
    displaySmall: baseText.displaySmall?.merge(headingStyle),
    headlineLarge: baseText.headlineLarge?.merge(headingStyle),
    headlineMedium: baseText.headlineMedium?.merge(headingStyle),
    headlineSmall: baseText.headlineSmall?.merge(headingStyle),
    titleLarge: baseText.titleLarge?.merge(headingStyle),
  );

  final cardRadius = BorderRadius.circular(t.radius);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    textTheme: textTheme,
    dividerColor: t.border,
    cardTheme: CardThemeData(
      color: t.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(color: t.border),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.background,
      foregroundColor: t.foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: t.card,
      selectedItemColor: t.primary,
      unselectedItemColor: t.mutedForeground,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: t.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.input),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.input),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.ring, width: 2),
      ),
      labelStyle: TextStyle(color: t.mutedForeground),
      hintStyle: TextStyle(color: t.mutedForeground),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: t.primary,
        foregroundColor: t.primaryForeground,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.foreground,
        side: BorderSide(color: t.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: t.primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.secondary,
      selectedColor: t.primary,
      labelStyle: TextStyle(color: t.secondaryForeground),
      side: BorderSide(color: t.border),
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.primary,
      linearTrackColor: t.secondary,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(t.radius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.popover,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
    ),
  );
}
