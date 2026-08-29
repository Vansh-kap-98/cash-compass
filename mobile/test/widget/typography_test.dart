import 'package:cash_compass/app/theme/app_theme.dart';
import 'package:cash_compass/app/theme/app_tokens.dart';
import 'package:cash_compass/state/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Regression tests for two reported Settings bugs.
///
/// 1. Selecting the Mono font pack blanked the screen. `google_fonts` throws on
///    an unknown family, and that throw happened while building `ThemeData` —
///    which `MaterialApp` reads on every build — so the whole widget tree
///    failed. The font name came from the web app's CSS, where the stack ends
///    in `monospace` and a miss is invisible.
///
/// 2. The text-size slider did nothing. Sizes were applied with
///    `TextTheme.apply(fontSizeFactor:)`, but Google Fonts styles carry a null
///    `fontSize`, and multiplying null yields null. Scaling now happens through
///    `MediaQuery.textScaler` at paint time instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // google_fonts fetches font files from fonts.gstatic.com on first use. There
  // is no network in a test run, and the resulting async failure is unrelated
  // to what these tests assert. Turning fetching off keeps the failures honest.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final tokens = appThemes[defaultThemeName]!;

  group('font packs', () {
    // Checked against the catalogue rather than by building a theme: building
    // one kicks off an async font download, which cannot succeed in a test and
    // would fail these for a reason that has nothing to do with the invariant.
    test('every declared family exists in the google_fonts catalogue', () {
      final catalogue = GoogleFonts.asMap().keys.toSet();

      for (final pack in FontPack.values) {
        for (final family in {pack.headingFont, pack.bodyFont}) {
          expect(
            catalogue,
            contains(family),
            reason: '"$family" (${pack.id} pack) is not in google_fonts. '
                'Asking for it throws, and that throw happens while building '
                'ThemeData — which blanks the whole screen. This is exactly '
                'how "Geist Mono" broke the Mono pack.',
          );
        }
      }
    });

    test('theme token fonts exist too', () {
      final catalogue = GoogleFonts.asMap().keys.toSet();

      for (final theme in appThemes.values) {
        for (final family in {theme.headingFont, theme.bodyFont}) {
          expect(catalogue, contains(family),
              reason: '"$family" in the ${theme.name} theme is not catalogued');
        }
      }
    });

    testWidgets('an unknown family degrades instead of blanking the screen',
        (tester) async {
      // Simulates the original bug: a token set naming a font that is not in
      // the catalogue. The app must still render.
      final bogus = AppTokens(
        name: 'bogus-font-theme',
        label: 'Bogus',
        headingFont: 'Definitely Not A Real Font',
        bodyFont: 'Also Not Real',
        monoFont: 'Not Real Either',
        popover: tokens.popover,
        popoverForeground: tokens.popoverForeground,
        radius: tokens.radius,
        background: tokens.background,
        foreground: tokens.foreground,
        card: tokens.card,
        cardForeground: tokens.cardForeground,
        primary: tokens.primary,
        primaryForeground: tokens.primaryForeground,
        secondary: tokens.secondary,
        secondaryForeground: tokens.secondaryForeground,
        muted: tokens.muted,
        mutedForeground: tokens.mutedForeground,
        accent: tokens.accent,
        accentForeground: tokens.accentForeground,
        destructive: tokens.destructive,
        destructiveForeground: tokens.destructiveForeground,
        border: tokens.border,
        input: tokens.input,
        ring: tokens.ring,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(bogus),
          home: const Scaffold(body: Text('still here')),
        ),
      );

      expect(
        find.text('still here'),
        findsOneWidget,
        reason: 'a missing font is decoration failing, not the app failing',
      );
    });
  });

  group('text size', () {
    /// Renders one line of body text and reports its laid-out height.
    Future<double> renderedHeight(WidgetTester tester, double scale) async {
      final stores = TestStores.empty();
      await stores.theme.setFontScale(scale);

      await tester.pumpWidget(
        wrapForTest(
          const Text('Sample', key: Key('probe')),
          stores: stores,
          textScale: stores.theme.fontSizeFactor,
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      final size = tester.getSize(find.byKey(const Key('probe')));
      await tester.pumpWidget(const SizedBox.shrink());
      return size.height;
    }

    testWidgets('120% renders visibly larger text than 85%', (tester) async {
      final small = await renderedHeight(tester, 85);
      final large = await renderedHeight(tester, 120);

      expect(
        large,
        greaterThan(small),
        reason: 'the slider previously moved and nothing on screen changed',
      );
    });

    test('the scale factor tracks the slider', () async {
      final theme = TestStores.empty().theme;

      await theme.setFontScale(120);
      expect(theme.fontSizeFactor, closeTo(1.2, 0.001));

      await theme.setFontScale(85);
      expect(theme.fontSizeFactor, closeTo(0.85, 0.001));
    });

    test('out-of-range values are clamped, not rejected', () async {
      final theme = TestStores.empty().theme;

      await theme.setFontScale(999);
      expect(theme.fontScalePercent, 120);

      await theme.setFontScale(0);
      expect(theme.fontScalePercent, 85);
    });
  });
}
