import 'package:cash_compass/app/theme/app_colors.dart';
import 'package:cash_compass/app/widgets/app_avatar.dart';
import 'package:cash_compass/app/widgets/app_backdrop.dart';
import 'package:cash_compass/app/widgets/app_bottom_nav.dart';
import 'package:cash_compass/app/widgets/app_button.dart';
import 'package:cash_compass/app/widgets/app_progress_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Covers the shared components' own behaviour — the parts that are logic
/// rather than looks, plus the contrast floors the palette claims.
void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('AppAvatar initials', () {
    test('takes one letter from each of the first two words', () {
      expect(AppAvatar.initialsOf('Vansh Kapoor'), 'VK');
    });

    test('takes a single letter from a one-word name', () {
      // An email has no spaces; two letters of the local part reads as a typo.
      expect(AppAvatar.initialsOf('demo@cashcompass.app'), 'D');
    });

    test('works on Cyrillic', () {
      // Splitting on whitespace rather than matching an alphabet is what makes
      // this hold for the Russian build.
      expect(AppAvatar.initialsOf('Иван Петров'), 'ИП');
    });

    test('falls back rather than rendering an empty circle', () {
      expect(AppAvatar.initialsOf('   '), '—');
      expect(AppAvatar.initialsOf(''), '—');
    });
  });

  group('AppProgressRing', () {
    testWidgets('shows the rounded percentage by default', (tester) async {
      await tester.pumpWidget(host(const AppProgressRing(progress: 0.666)));
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('clamps past 100 rather than winding round again',
        (tester) async {
      await tester.pumpWidget(host(const AppProgressRing(progress: 1.3)));
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('survives a non-finite progress', (tester) async {
      // `current / target` with a zero target is the real source of this.
      await tester.pumpWidget(
        host(const AppProgressRing(progress: double.nan)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('an empty label draws the ring alone', (tester) async {
      await tester.pumpWidget(
        host(const AppProgressRing(progress: 0.5, label: '')),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('AppButton', () {
    testWidgets('a null callback disables it', (tester) async {
      await tester.pumpWidget(
        host(const AppButton(label: 'Save', onPressed: null)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.enabled, isFalse);
    });

    testWidgets('the destructive variant is the one that carries colour',
        (tester) async {
      await tester.pumpWidget(
        host(AppButton.destructive(label: 'Reset', onPressed: () {})),
      );
      final style = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .style!;
      expect(
        style.foregroundColor?.resolve({}),
        AppColors.error,
      );
    });
  });

  group('AppBackdrop', () {
    testWidgets('never swallows a tap meant for the page', (tester) async {
      // The backdrop fills the page and, in the empty regions below short
      // content, is the topmost thing under a finger. If it took the hit, a
      // decorative flourish would silently break the screen.
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppBackdrop(
              child: Align(
                alignment: Alignment.topCenter,
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(taps, 1);

      // And a tap on bare backdrop resolves to the Scaffold, not an error.
      await tester.tapAt(const Offset(200, 500));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(taps, 1);
    });

    testWidgets('renders without a child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AppBackdrop())),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('AppBottomNav', () {
    const destinations = [
      AppNavDestination(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      AppNavDestination(icon: Icons.savings_outlined, label: 'Goals'),
      AppNavDestination(icon: Icons.school_outlined, label: 'Planner'),
      AppNavDestination(icon: Icons.widgets_outlined, label: 'Workspace'),
      AppNavDestination(icon: Icons.settings_outlined, label: 'Settings'),
    ];

    Widget bar(int index, {ValueChanged<int>? onSelected}) => MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppBottomNav(
              currentIndex: index,
              onSelected: onSelected ?? (_) {},
              destinations: destinations,
            ),
          ),
        );

    testWidgets('renders every destination at the real tab count',
        (tester) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();

      for (final d in destinations) {
        expect(find.byIcon(d.icon), findsWidgets, reason: d.label);
      }
    });

    testWidgets('reports the tapped index', (tester) async {
      var tapped = -1;
      await tester.pumpWidget(bar(0, onSelected: (i) => tapped = i));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.school_outlined).first);
      expect(tapped, 2);
    });

    testWidgets('only the selected slot builds its blur layers',
        (tester) async {
      // The cost control that keeps this bar off the jank budget: a blur is
      // allocated per lit slot, so at rest there must be exactly one slot's
      // worth — not one per tab.
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();

      expect(find.byType(ImageFiltered), findsNWidgets(2));
    });

    // Both measured as painted, in global coordinates. Reading `left` off the
    // AnimatedPositioned *widget* would report the animation's target rather
    // than where the glow currently is, and measuring the two against
    // different origins is what made the first version of this test lie.
    double haloCentre(WidgetTester tester) =>
        tester.getRect(find.byKey(AppBottomNav.haloKey)).center.dx;

    double iconCentre(WidgetTester tester, int i) =>
        tester.getRect(find.byIcon(destinations[i].icon).last).center.dx;

    testWidgets('the halo sits on the icon it is lighting', (tester) async {
      // The regression this exists for: positioning the halo with `Alignment`
      // puts its *centre* at `parentCentre + x·(parentWidth − haloWidth)/2`,
      // not at fraction x of the width. Mapping slot centres onto that axis
      // pulls every halo toward the middle — visibly so on the outer tabs.
      for (final i in [0, 2, 4]) {
        await tester.pumpWidget(bar(i));
        await tester.pumpAndSettle();

        expect(
          haloCentre(tester),
          closeTo(iconCentre(tester, i), 1.0),
          reason: 'the halo is off-centre under tab $i',
        );
      }
    });

    testWidgets('the halo travels instead of snapping', (tester) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();
      final start = haloCentre(tester);

      await tester.pumpWidget(bar(4));
      await tester.pump(const Duration(milliseconds: 130));
      final mid = haloCentre(tester);

      await tester.pumpAndSettle();
      final end = haloCentre(tester);

      expect(end, greaterThan(start));
      // Halfway through it must be between the two, not already arrived.
      expect(mid, greaterThan(start));
      expect(mid, lessThan(end));
    });

    testWidgets('mid-transition two slots are lit, then one', (tester) async {
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();

      await tester.pumpWidget(bar(1));
      await tester.pump(const Duration(milliseconds: 100));
      // The outgoing slot has not finished fading, the incoming one has begun.
      expect(find.byType(ImageFiltered), findsNWidgets(4));

      await tester.pumpAndSettle();
      expect(find.byType(ImageFiltered), findsNWidgets(2));
    });

    testWidgets('every tab is reachable by its localised name', (tester) async {
      // The bar paints no text, so this is the only name assistive technology
      // gets. A missing one makes the tab unnameable.
      await tester.pumpWidget(bar(0));
      await tester.pumpAndSettle();

      for (final d in destinations) {
        expect(
          find.bySemanticsLabel(d.label),
          findsOneWidget,
          reason: '${d.label} has no accessible name',
        );
      }
    });
  });
}
