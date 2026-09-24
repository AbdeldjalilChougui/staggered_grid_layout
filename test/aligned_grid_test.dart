import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout/staggered_grid_layout.dart';

import 'helpers.dart';

double heightOf(int i) => 40.0 + (i * 53) % 80;

void main() {
  group('SliverAlignedGrid', () {
    testWidgets('rows take the extent of their tallest child', (tester) async {
      const heights = <double>[50, 100, 70, 40, 40, 40, 30];
      await tester.pumpWidget(frame(
        CustomScrollView(slivers: [
          SliverAlignedGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            itemCount: heights.length,
            itemBuilder: (context, i) => box(i, height: heights[i]),
          ),
        ]),
      ));
      for (var i = 0; i < 3; i++) {
        expect(rectOf(tester, i), Rect.fromLTWH(i * 100.0, 0, 100, 100));
      }
      for (var i = 3; i < 6; i++) {
        expect(rectOf(tester, i), Rect.fromLTWH((i - 3) * 100.0, 110, 100, 40));
      }
      expect(rectOf(tester, 6), const Rect.fromLTWH(0, 160, 100, 30));
    });

    testWidgets('children without an explicit size are stretched',
        (tester) async {
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          crossAxisCount: 2,
          itemCount: 2,
          itemBuilder: (context, i) => i == 0
              ? box(0, height: 120)
              : Container(
                  key: const ValueKey<int>(1), color: const Color(0xFF000000)),
        ),
      ));
      expect(rectOf(tester, 1), const Rect.fromLTWH(150, 0, 150, 120));
    });

    testWidgets('cross axis spacing, padding and RTL', (tester) async {
      await tester.pumpWidget(frame(
        width: 320,
        textDirection: TextDirection.rtl,
        AlignedGridView.count(
          padding: const EdgeInsets.all(10),
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 5,
          itemCount: 3,
          itemBuilder: (context, i) => box(i, height: 50),
        ),
      ));
      // Inner width 300, (300 - 20) / 2 = 140.
      expect(rectOf(tester, 0), const Rect.fromLTWH(170, 10, 140, 50));
      expect(rectOf(tester, 1), const Rect.fromLTWH(10, 10, 140, 50));
      expect(rectOf(tester, 2), const Rect.fromLTWH(170, 65, 140, 50));
    });

    testWidgets('horizontal axis', (tester) async {
      const widths = <double>[30, 80, 50, 40];
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          scrollDirection: Axis.horizontal,
          crossAxisCount: 2,
          itemCount: widths.length,
          itemBuilder: (context, i) => box(i, width: widths[i]),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 80, 300));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 300, 80, 300));
      expect(rectOf(tester, 2), const Rect.fromLTWH(80, 0, 50, 300));
    });

    testWidgets('extent constructor', (tester) async {
      await tester.pumpWidget(frame(
        AlignedGridView.extent(
          maxCrossAxisExtent: 100,
          itemCount: 4,
          itemBuilder: (context, i) => box(i, height: 20),
        ),
      ));
      expect(rectOf(tester, 3), const Rect.fromLTWH(0, 20, 100, 20));
    });

    testWidgets('builds only visible rows plus the cache extent',
        (tester) async {
      final built = <int>{};
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          cacheExtent: 50,
          crossAxisCount: 4,
          itemCount: 1000,
          itemBuilder: (context, i) {
            built.add(i);
            return box(i, height: 100);
          },
        ),
      ));
      // Rows starting before 650: 7 rows of 4.
      expect(built, {for (var i = 0; i < 28; i++) i});
    });

    testWidgets('scrolling does not rebuild children already built',
        (tester) async {
      final builds = <int, int>{};
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          controller: controller,
          crossAxisCount: 3,
          itemCount: 300,
          itemBuilder: (context, i) {
            builds[i] = (builds[i] ?? 0) + 1;
            return box(i, height: heightOf(i));
          },
        ),
      ));
      for (var step = 0; step < 10; step++) {
        controller.jumpTo(controller.offset + 7);
        await tester.pump();
      }
      expect(builds[0], 1);
      expect(builds[3], 1);
    });

    testWidgets('no itemCount does not hang', (tester) async {
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          crossAxisCount: 2,
          itemBuilder: (context, i) => box(i, height: 30),
        ),
      ));
      expect(isBuilt(0), isTrue);
      await tester.drag(find.byType(Scrollable), const Offset(0, -3000));
      await tester.pump();
    });

    testWidgets('a builder returning null ends the grid', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        AlignedGridView.count(
          controller: controller,
          crossAxisCount: 2,
          itemBuilder: (context, i) => i < 25 ? box(i, height: 100) : null,
        ),
      ));
      controller.jumpTo(100000);
      await tester.pumpAndSettle();
      expect(controller.position.maxScrollExtent, 1300 - 600);
    });

    testWidgets('a row shrinks when its tallest child shrinks', (tester) async {
      var tall = true;
      Widget build() => frame(
            AlignedGridView.count(
              crossAxisCount: 2,
              itemCount: 4,
              itemBuilder: (context, i) =>
                  box(i, height: i == 1 && tall ? 200 : 50),
            ),
          );
      await tester.pumpWidget(build());
      expect(rectOf(tester, 0).height, 200);
      tall = false;
      await tester.pumpWidget(build());
      expect(rectOf(tester, 0).height, 50);
      expect(rectOf(tester, 2).top, 50);
    });

    testWidgets('no jumps when scrolling up after rows resized off-screen',
        (tester) async {
      final controller = ScrollController();
      var grow = false;
      Widget build() => frame(
            AlignedGridView.count(
              controller: controller,
              cacheExtent: 0,
              crossAxisCount: 3,
              itemCount: 600,
              itemBuilder: (context, i) =>
                  box(i, height: heightOf(i) + (grow && i < 150 ? 33 : 0)),
            ),
          );
      await tester.pumpWidget(build());
      for (var offset = 0.0; offset <= 6000; offset += 400) {
        controller.jumpTo(offset);
        await tester.pump();
      }
      grow = true;
      await tester.pumpWidget(build());
      var tracked = List<int>.generate(600, (i) => i).lastWhere(isBuilt);
      var lastTop = rectOf(tester, tracked).top;
      for (var step = 0; step < 300; step++) {
        final target = controller.offset - 25;
        if (target < 300) break;
        controller.jumpTo(target);
        await tester.pump();
        if (!isBuilt(tracked) || rectOf(tester, tracked).top > 560) {
          tracked = List<int>.generate(600, (i) => i)
              .lastWhere((i) => isBuilt(i) && rectOf(tester, i).top < 400);
          lastTop = rectOf(tester, tracked).top;
          continue;
        }
        final top = rectOf(tester, tracked).top;
        expect(top - lastTop, closeTo(25, 0.001),
            reason: 'child $tracked jumped at step $step');
        lastTop = top;
      }
    });

    testWidgets('keeps alive, reorders and changes column count safely',
        (tester) async {
      final controller = ScrollController();
      var ids = List<int>.generate(90, (i) => i);
      var columns = 3;
      Widget build() => frame(
            AlignedGridView.count(
              controller: controller,
              crossAxisCount: columns,
              itemCount: ids.length,
              findChildIndexCallback: (key) {
                final index = ids.indexOf((key as ValueKey<int>).value);
                return index < 0 ? null : index;
              },
              itemBuilder: (context, i) =>
                  box(ids[i], height: heightOf(ids[i])),
            ),
          );
      await tester.pumpWidget(build());
      controller.jumpTo(700);
      await tester.pump();
      ids = ids.reversed.toList();
      await tester.pumpWidget(build());
      ids.removeRange(5, 50);
      await tester.pumpWidget(build());
      columns = 4;
      await tester.pumpWidget(build());
      ids.insertAll(0, [700, 701]);
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      controller.jumpTo(0);
      await tester.pump();
      expect(rectOf(tester, 700).topLeft, Offset.zero);
      expect(rectOf(tester, 701).left, 75);
    });
  });
}
