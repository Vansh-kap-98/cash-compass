import 'package:cash_compass/screens/tabs/settings_tab.dart';
import 'package:cash_compass/state/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// The Settings tab is where the language option lives, so it is the one
/// screen that has to hold up in both languages and drive the change itself.
void main() {
  testWidgets('the language section offers every language, naming each in its '
      'own tongue', (tester) async {
    final stores = TestStores.populated();
    await tester.pumpWidget(
      wrapForTest(const SettingsTab(), stores: stores),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Language'), findsOneWidget);

    // A person stranded in a language they cannot read has to be able to spot
    // their own here, so neither entry is ever translated.
    await tester.tap(find.byType(DropdownButtonFormField<AppLanguage>));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsWidgets);
    expect(find.text('Русский'), findsWidgets);
    expect(find.text('System default'), findsWidgets);

    // Close the menu so the test tears down cleanly.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('choosing Russian stores the preference', (tester) async {
    final stores = TestStores.populated();
    await tester.pumpWidget(
      wrapForTest(const SettingsTab(), stores: stores),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(DropdownButtonFormField<AppLanguage>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Русский').last);
    await tester.pumpAndSettle();

    expect(stores.locale.language, AppLanguage.russian);
    expect(stores.locale.locale, const Locale('ru'));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the whole page renders in Russian', (tester) async {
    final stores = TestStores.populated();
    await tester.pumpWidget(
      wrapForTest(
        const SettingsTab(),
        stores: stores,
        locale: const Locale('ru'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Язык'), findsOneWidget);
    expect(find.text('Валюта'), findsOneWidget);
    // No "Тема" section: the palette is fixed and the picker is gone.
    expect(find.text('Тема'), findsNothing);

    // Nothing English left over above the fold.
    expect(find.text('Language'), findsNothing);
    expect(find.text('Currency'), findsNothing);

    // The rest of the page is below the test viewport, and a ListView does not
    // build what it cannot show — so scroll rather than assert on unbuilt rows.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('Аккаунт'), findsOneWidget);
    expect(find.text('Данные'), findsOneWidget);
    expect(find.text('Account'), findsNothing);

    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the page survives Russian at the largest text scale',
      (tester) async {
    // Russian labels are longer, and this page stacks a dropdown, a slider and
    // several buttons — the combination that overflows first.
    await pumpAndExpectClean(
      tester,
      const SettingsTab(),
      stores: TestStores.populated(),
      textScale: 1.3,
      locale: const Locale('ru'),
      reason: 'the settings page overflowed in Russian at 1.3x text scale',
    );
  });
}
