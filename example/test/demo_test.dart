import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout_example/main.dart';

void main() {
  for (final rtl in [false, true]) {
    for (final demo in demos) {
      testWidgets('${demo.title} renders and scrolls (rtl: $rtl)',
          (tester) async {
        await tester.pumpWidget(const DemoApp());
        if (rtl) {
          await tester.tap(find.byType(Switch));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text(demo.title));
        await tester.pumpAndSettle();
        final scrollable = find.byType(Scrollable).last;
        await tester.fling(scrollable, const Offset(0, -800), 2000);
        await tester.fling(scrollable, const Offset(-800, 0), 2000);
        await tester.pumpAndSettle();
        await tester.fling(scrollable, const Offset(0, 800), 2000);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('masonry demo resizes, inserts and shuffles', (tester) async {
    await tester.pumpWidget(const DemoApp());
    await tester.tap(find.text('Masonry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('0'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Insert at the top'));
    await tester.pumpAndSettle();
    expect(find.text('200'), findsOneWidget);
    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
