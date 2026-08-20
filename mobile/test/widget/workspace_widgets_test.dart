import 'package:cash_compass/models/workspace_widget.dart';
import 'package:cash_compass/screens/tabs/workspace_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Renders every workspace widget in every configuration it can actually be
/// seen in, and fails on any exception — including a RenderFlex overflow.
///
/// This is the coverage that was missing: before it, only 2 of the 15 widget
/// bodies had ever executed, and five of them overflowed their card.
void main() {
  // A phone-width viewport. Card width matters because a narrower card wraps
  // text to more lines, which is what pushes a body past its height.
  const phoneWidth = 380.0;

  Widget card(WorkspaceWidgetType type, WidgetSize size, {required bool editing}) {
    return Center(
      child: SizedBox(
        width: phoneWidth,
        child: WorkspaceCard(
          widget: WorkspaceWidget(
            id: 'test-${type.name}',
            type: type,
            size: size,
          ),
          index: 0,
          editing: editing,
        ),
      ),
    );
  }

  group('every widget renders without overflow', () {
    for (final type in WorkspaceWidgetType.values) {
      for (final size in WidgetSize.values) {
        for (final editing in [false, true]) {
          final mode = editing ? 'edit' : 'view';

          testWidgets('${type.name} · ${size.name} · $mode · populated',
              (tester) async {
            await pumpAndExpectClean(
              tester,
              card(type, size, editing: editing),
              stores: TestStores.populated(),
              reason: '${type.name} overflowed at ${size.name} in $mode mode '
                  'with data',
            );
          });

          testWidgets('${type.name} · ${size.name} · $mode · empty',
              (tester) async {
            // Empty stores are where divide-by-zero and null faults live.
            await pumpAndExpectClean(
              tester,
              card(type, size, editing: editing),
              stores: TestStores.empty(),
              reason: '${type.name} broke at ${size.name} in $mode mode with '
                  'no data',
            );
          });
        }
      }
    }
  });

  group('widgets survive the largest text scale', () {
    // The Settings slider reaches 120%, and Android accessibility can push
    // well beyond that. Small cards are where it bites first.
    for (final type in WorkspaceWidgetType.values) {
      testWidgets('${type.name} · small · edit · 1.3x text', (tester) async {
        await pumpAndExpectClean(
          tester,
          card(type, WidgetSize.small, editing: true),
          stores: TestStores.populated(),
          textScale: 1.3,
          reason: '${type.name} overflowed at 1.3x text scale',
        );
      });
    }
  });

  testWidgets('the size toggle does not change the space the body gets',
      (tester) async {
    // Regression guard for the original bug: edit mode added ~24px of header,
    // silently shrinking every body the moment the user tapped Edit.
    final stores = TestStores.populated();

    double bodyHeight(WidgetTester t) {
      final clip = t.widget<ClipRect>(find.byType(ClipRect).first);
      return t.getSize(find.byWidget(clip)).height;
    }

    await tester.pumpWidget(
      wrapForTest(
        card(WorkspaceWidgetType.todaySnapshot, WidgetSize.medium,
            editing: false),
        stores: stores,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final viewHeight = bodyHeight(tester);

    await tester.pumpWidget(
      wrapForTest(
        card(WorkspaceWidgetType.todaySnapshot, WidgetSize.medium,
            editing: true),
        stores: stores,
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final editHeight = bodyHeight(tester);

    expect(
      editHeight,
      viewHeight,
      reason: 'edit mode must not steal height from the widget body',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
