import 'package:cash_compass/screens/tabs/dashboard_tab.dart';
import 'package:cash_compass/screens/tabs/goals_tab.dart';
import 'package:cash_compass/screens/tabs/planner_tab.dart';
import 'package:cash_compass/screens/tabs/settings_tab.dart';
import 'package:cash_compass/screens/tabs/workspace_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Renders each tab at phone width and fails on any exception — including a
/// RenderFlex overflow.
///
/// The workspace sweep next door covers the 15 widget bodies; nothing covered
/// the tabs themselves. That gap mattered the moment the type changed: the
/// monochrome scale sets larger explicit sizes than the Material defaults it
/// replaced, and buttons grew from 48 to 52, so every horizontal row on these
/// pages got tighter at once.
///
/// The matrix is language x text scale because those are the two multipliers
/// that stack: Russian runs longer than English, the Settings slider reaches
/// 120%, and Android accessibility goes beyond that.
void main() {
  // A small phone. 360dp is the narrowest width in common use, and narrower
  // is where a Row that "looks fine" gives way.
  const phone = Size(360, 780);

  final tabs = <String, Widget>{
    'dashboard': const DashboardTab(),
    'goals': const GoalsTab(),
    'planner': const PlannerTab(),
    'workspace': const WorkspaceTab(),
    'settings': const SettingsTab(),
  };

  const locales = {'en': Locale('en'), 'ru': Locale('ru')};

  Future<void> render(
    WidgetTester tester,
    Widget tab, {
    required TestStores stores,
    required Locale locale,
    required double textScale,
    required String reason,
  }) async {
    tester.view.physicalSize = phone * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await pumpAndExpectClean(
      tester,
      tab,
      stores: stores,
      locale: locale,
      textScale: textScale,
      reason: reason,
    );
  }

  for (final tab in tabs.entries) {
    for (final locale in locales.entries) {
      testWidgets('${tab.key} · ${locale.key} · populated', (tester) async {
        await render(
          tester,
          tab.value,
          stores: TestStores.populated(),
          locale: locale.value,
          textScale: 1.0,
          reason: '${tab.key} overflowed in ${locale.key} with data',
        );
      });

      testWidgets('${tab.key} · ${locale.key} · empty', (tester) async {
        // Empty stores are where divide-by-zero and null faults live.
        await render(
          tester,
          tab.value,
          stores: TestStores.empty(),
          locale: locale.value,
          textScale: 1.0,
          reason: '${tab.key} broke in ${locale.key} with no data',
        );
      });

      testWidgets('${tab.key} · ${locale.key} · 1.3x text', (tester) async {
        await render(
          tester,
          tab.value,
          stores: TestStores.populated(),
          locale: locale.value,
          textScale: 1.3,
          reason: '${tab.key} overflowed in ${locale.key} at 1.3x text',
        );
      });
    }
  }
}
