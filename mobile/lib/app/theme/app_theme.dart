import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dev/log.dart';
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
/// [fontPack] comes from the Settings control; it overrides the theme's own
/// font choices when the user picks a non-default one.
///
/// Text *size* is deliberately not handled here — see `main.dart`, which scales
/// through `MediaQuery.textScaler`. Doing it in [ThemeData] does not work:
/// `GoogleFonts` returns styles with a null `fontSize`, and
/// `TextStyle.apply(fontSizeFactor:)` multiplies that null into nothing, so the
/// slider silently did nothing in release and asserted in debug.
ThemeData buildTheme(
  AppTokens t, {
  FontPack fontPack = FontPack.defaultPack,
}) {
  // A theme change rebuilds MaterialApp, which would otherwise rebuild the
  // whole Google Fonts text theme (15+ TextStyles) every time. Memoising makes
  // a repeat call a map lookup. The key space is tiny: 5 themes x 3 font packs.
  final key = '${t.name}|${fontPack.id}';
  final cached = _themeCache[key];
  if (cached != null) return cached;

  final built = _buildTheme(t, fontPack);
  _themeCache[key] = built;
  return built;
}

final Map<String, ThemeData> _themeCache = {};

/// [GoogleFonts.getTextTheme], degrading to [base] if the family is unknown.
///
/// The font names came from `frontend/src/index.css`, where every stack ends in
/// a generic fallback — `'Geist Mono', monospace` — so a missing family is
/// invisible on the web. `google_fonts` has no such fallback: it throws
/// `"No font family by name '...' was found."`
///
/// That throw happens while building [ThemeData], which `MaterialApp` reads on
/// every build, so one unrecognised name took down the entire widget tree and
/// the user saw a blank screen. A font is decoration; it must never be able to
/// do that. Falling back mirrors what CSS already does.
TextTheme _textTheme(String family, TextTheme base) {
  try {
    return GoogleFonts.getTextTheme(family, base);
  } catch (error) {
    logError('Font family "$family"', error);
    return base;
  }
}

/// [GoogleFonts.getFont], degrading to a plain coloured style. See [_textTheme].
TextStyle _font(String family, Color color) {
  try {
    return GoogleFonts.getFont(family, color: color);
  } catch (error) {
    logError('Font family "$family"', error);
    return TextStyle(color: color);
  }
}

/// The radius scale, carried on [ThemeData] so widgets can ask for it instead
/// of guessing a literal.
///
/// Widgets that draw their own rounded surface — an [InkWell] ripple over an
/// [InputDecorator], an image thumbnail — previously hardcoded 12 while the
/// input border beside them was 12 and the button above them was 14. Reading
/// the scale keeps a ripple aligned to the field it sits in when either moves.
@immutable
class AppRadii extends ThemeExtension<AppRadii> {
  const AppRadii({
    required this.surface,
    required this.control,
    required this.small,
  });

  /// Cards, sheets, dialogs.
  final double surface;

  /// Buttons, inputs, chips, and anything that ripples over them.
  final double control;

  /// Thumbnails, swatches, inline bars.
  final double small;

  BorderRadius get controlBorder => BorderRadius.circular(control);
  BorderRadius get smallBorder => BorderRadius.circular(small);

  @override
  AppRadii copyWith({double? surface, double? control, double? small}) =>
      AppRadii(
        surface: surface ?? this.surface,
        control: control ?? this.control,
        small: small ?? this.small,
      );

  @override
  AppRadii lerp(AppRadii? other, double s) {
    if (other == null) return this;
    return AppRadii(
      surface: lerpDouble(surface, other.surface, s)!,
      control: lerpDouble(control, other.control, s)!,
      small: lerpDouble(small, other.small, s)!,
    );
  }
}

/// Shorthand for `Theme.of(context).extension<AppRadii>()`, falling back to the
/// default scale so a theme built without the extension still renders.
extension AppRadiiAccess on ThemeData {
  AppRadii get radii =>
      extension<AppRadii>() ??
      const AppRadii(surface: 24, control: 14, small: 8);
}

ThemeData _buildTheme(AppTokens t, FontPack fontPack) {
  final scheme = ColorScheme(
    brightness: ThemeData.estimateBrightnessForColor(t.background),
    primary: t.primary,
    onPrimary: t.primaryForeground,
    // The supplied brand colour is too light to be type, so it fills surfaces
    // here while `primary` stays the darkened, legible version. See AppTokens.
    primaryContainer: t.primaryContainer ?? t.primary,
    onPrimaryContainer: t.onPrimaryContainer ?? t.primaryForeground,
    secondary: t.secondary,
    onSecondary: t.secondaryForeground,
    // `accent` had no slot in the ColorScheme, so nothing in the widget tree
    // could reach it — which is how it went unnoticed that Soft Bloom's accent
    // was pure white. Mapping it to the tertiary slots gives it a name widgets
    // can ask for; a theme that omits the container pair falls back to accent.
    tertiary: t.accent,
    onTertiary: t.accentForeground,
    tertiaryContainer: t.accentContainer ?? t.accent,
    onTertiaryContainer: t.onAccentContainer ?? t.accentForeground,
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
  final bodyFamily =
      fontPack == FontPack.defaultPack ? t.bodyFont : fontPack.bodyFont;
  final headingFamily =
      fontPack == FontPack.defaultPack ? t.headingFont : fontPack.headingFont;

  // Colour only. These styles carry a null `fontSize` by design — sizes resolve
  // from the Material defaults downstream, and the user's scale is applied at
  // render time via MediaQuery rather than baked in here.
  final baseText = _textTheme(bodyFamily, const TextTheme()).apply(
    bodyColor: t.foreground,
    displayColor: t.foreground,
  );

  // Headings use the heading font; body styles keep the body font.
  // This style carries no `fontSize`, so merging it below overrides the family
  // without undoing the scaling applied above.
  //
  // The weight is part of the pairing, not decoration. Outfit at w600 against
  // Inter at w400 is what separates a heading from a paragraph when both sit at
  // similar sizes — without it the two families are near enough to read as one.
  final headingStyle =
      _font(headingFamily, t.foreground).copyWith(fontWeight: FontWeight.w600);

  // `titleMedium` and `titleSmall` are included deliberately. `titleMedium` is
  // the card-title style and is used 28 times across the app; while only
  // `titleLarge` and the `headline*` sizes took the heading font, Outfit
  // appeared on eight surfaces in total and every card heading rendered in
  // Inter — so the app had two declared fonts and effectively shipped one.
  final textTheme = baseText.copyWith(
    displayLarge: baseText.displayLarge?.merge(headingStyle),
    displayMedium: baseText.displayMedium?.merge(headingStyle),
    displaySmall: baseText.displaySmall?.merge(headingStyle),
    headlineLarge: baseText.headlineLarge?.merge(headingStyle),
    headlineMedium: baseText.headlineMedium?.merge(headingStyle),
    headlineSmall: baseText.headlineSmall?.merge(headingStyle),
    titleLarge: baseText.titleLarge?.merge(headingStyle),
    titleMedium: baseText.titleMedium?.merge(headingStyle),
    titleSmall: baseText.titleSmall?.merge(headingStyle),
  );

  final cardRadius = BorderRadius.circular(t.radius);
  final controlRadius = BorderRadius.circular(t.radiusControl);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [
      AppRadii(
        surface: t.radius,
        control: t.radiusControl,
        small: t.radiusSmall,
      ),
    ],
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.input),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.input),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.ring, width: 2),
      ),
      // Errors were previously drawn with the Material default red rather than
      // the theme's destructive colour, so the one state that most needs to be
      // unmistakable was the only one off-palette.
      errorBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.destructive, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: t.border),
      ),
      labelStyle: TextStyle(color: t.mutedForeground),
      hintStyle: TextStyle(color: t.mutedForeground),
      errorStyle: TextStyle(color: t.destructive),
    ),
    // Buttons share one padding rule and one radius. Vertical padding is 12 --
    // on the 4px grid -- with the 48dp minimum touch target stated explicitly
    // rather than smuggled in as an off-grid 14.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        // Filled surfaces carry the supplied Wisteria with dark ink on it --
        // white on that blue is 2.64:1, so the label has to be the dark one.
        backgroundColor: t.primaryContainer ?? t.primary,
        foregroundColor: t.onPrimaryContainer ?? t.primaryForeground,
        disabledBackgroundColor: t.secondary,
        disabledForegroundColor: t.mutedForeground,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.foreground,
        disabledForegroundColor: t.mutedForeground,
        side: BorderSide(color: t.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.primary,
        disabledForegroundColor: t.mutedForeground,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    ),
    // A selected chip fills with `primary`. The label previously stayed
    // `secondaryForeground` in both states, so a selected chip drew dark ink on
    // a dark plum fill. Resolving the label and the border per state keeps both
    // states legible instead of only the unselected one.
    chipTheme: ChipThemeData(
      backgroundColor: t.secondary,
      selectedColor: t.primaryContainer ?? t.primary,
      checkmarkColor: t.onPrimaryContainer ?? t.primaryForeground,
      labelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? (t.onPrimaryContainer ?? t.primaryForeground)
              : t.secondaryForeground,
          fontWeight: FontWeight.w500,
        ),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? (t.primaryContainer ?? t.primary)
              : t.border,
        ),
      ),
      shape: const StadiumBorder(),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.primary,
      linearTrackColor: t.secondary,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.popover,
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
    ),
  );
}
