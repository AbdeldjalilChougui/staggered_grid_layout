import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout/staggered_grid_layout.dart';

import 'helpers.dart';

double heightOf(int i) => 60.0 + (i * 37) % 90;

void main() {
  group('SliverMasonryGrid placement', () {
    testWidgets('places children in the shortest column', (tester) async {
      const heights = <double>[100, 50, 80, 30, 60, 20];
      await tester.pumpWidget(frame(
        CustomScrollView(slivers: [
          SliverMasonryGrid.count(
            crossAxisCount: 3,
            childCount: heights.length,
            itemBuilder: (context, i) => box(i, height: heights[i]),
          ),
        ]),
      ));
      // col0: 0(100) | col1: 1(50) 3(30) 4(60) | col2: 2(80) 5(20)
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 100, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 50));
      expect(rectOf(tester, 2), const Rect.fromLTWH(200, 0, 100, 80));
      expect(rectOf(tester, 3), const Rect.fromLTWH(100, 50, 100, 30));
      // col1 and col2 both end at 80: tie goes to the lowest column.
      expect(rectOf(tester, 4), const Rect.fromLTWH(100, 80, 100, 60));
      expect(rectOf(tester, 5), const Rect.fromLTWH(200, 80, 100, 20));
    });

    testWidgets('equal heights fill columns left to right', (tester) async {
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          crossAxisCount: 3,
          itemCount: 9,
          itemBuilder: (context, i) => box(i, height: 100),
        ),
      ));
      for (var i = 0; i < 9; i++) {
        expect(rectOf(tester, i).topLeft,
            Offset((i % 3) * 100.0, (i ~/ 3) * 100.0));
      }
    });

    testWidgets('extent constructor derives the column count', (tester) async {
      await tester.pumpWidget(frame(
        MasonryGridView.extent(
          maxCrossAxisExtent: 120,
          itemCount: 4,
          itemBuilder: (context, i) => box(i, height: 50),
        ),
      ));
      // ceil(300 / 120) = 3 columns of 100.
      expect(rectOf(tester, 2), const Rect.fromLTWH(200, 0, 100, 50));
      expect(rectOf(tester, 3), const Rect.fromLTWH(0, 50, 100, 50));
    });

    testWidgets('spacing and padding', (tester) async {
      const heights = <double>[100, 40, 70, 30];
      await tester.pumpWidget(frame(
        width: 332,
        MasonryGridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 15,
          itemCount: heights.length,
          itemBuilder: (context, i) => box(i, height: heights[i]),
        ),
      ));
      // Inner width 300, (300 - 2 * 15) / 3 = 90.
      expect(rectOf(tester, 0), const Rect.fromLTWH(16, 16, 90, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(121, 16, 90, 40));
      expect(rectOf(tester, 2), const Rect.fromLTWH(226, 16, 90, 70));
      // Shortest is col1 (40) -> 16 + 40 + 8.
      expect(rectOf(tester, 3), const Rect.fromLTWH(121, 64, 90, 30));
    });

    testWidgets('RTL mirrors the columns', (tester) async {
      const heights = <double>[100, 50, 80, 30];
      await tester.pumpWidget(frame(
        textDirection: TextDirection.rtl,
        MasonryGridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 0,
          itemCount: heights.length,
          itemBuilder: (context, i) => box(i, height: heights[i]),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(200, 0, 100, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 50));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 0, 100, 80));
      expect(rectOf(tester, 3), const Rect.fromLTWH(100, 50, 100, 30));
    });

    testWidgets('horizontal axis uses rows as tracks', (tester) async {
      const widths = <double>[100, 50, 80];
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          scrollDirection: Axis.horizontal,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          itemCount: widths.length,
          itemBuilder: (context, i) => box(i, width: widths[i]),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 100, 300));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 300, 50, 300));
      expect(rectOf(tester, 2), const Rect.fromLTWH(60, 300, 80, 300));
    });

    testWidgets('reverse main axis', (tester) async {
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          reverse: true,
          crossAxisCount: 2,
          itemCount: 3,
          itemBuilder: (context, i) => box(i, height: 100),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 500, 150, 100));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 400, 150, 100));
    });
  });

  group('SliverMasonryGrid laziness', () {
    testWidgets('builds only visible children plus the cache extent',
        (tester) async {
      final built = <int>{};
      await tester.pumpWidget(frame(
        CustomScrollView(cacheExtent: 100, slivers: [
          SliverMasonryGrid.count(
            crossAxisCount: 3,
            childCount: 1000,
            itemBuilder: (context, i) {
              built.add(i);
              return box(i, height: 100);
            },
          ),
        ]),
      ));
      // Rows start at 0..600: 7 rows of 3 fit in 600 + 100.
      expect(built, {for (var i = 0; i < 21; i++) i});
      expect(isBuilt(21), isFalse);
    });

    testWidgets('disposes children that scroll out', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          controller: controller,
          cacheExtent: 0,
          crossAxisCount: 2,
          itemCount: 1000,
          itemBuilder: (context, i) => box(i, height: 100),
        ),
      ));
      controller.jumpTo(5000);
      await tester.pump();
      expect(isBuilt(0), isFalse);
      expect(isBuilt(100), isTrue);
      expect(rectOf(tester, 100).top, 0);
      // Only one viewport worth of children is alive.
      expect(
        find.byType(SizedBox, skipOffstage: false).evaluate().length,
        lessThanOrEqualTo(16),
      );
    });

    testWidgets('infinite builder without itemCount does not hang',
        (tester) async {
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          crossAxisCount: 2,
          itemBuilder: (context, i) => box(i, height: heightOf(i)),
        ),
      ));
      expect(isBuilt(0), isTrue);
      await tester.drag(find.byType(Scrollable), const Offset(0, -2000));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('builder returning null ends the grid', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          controller: controller,
          crossAxisCount: 2,
          itemBuilder: (context, i) => i < 30 ? box(i, height: 100) : null,
        ),
      ));
      controller.jumpTo(100000);
      await tester.pumpAndSettle();
      // 15 rows of 100.
      expect(controller.position.maxScrollExtent, 1500 - 600);
    });

    testWidgets('scroll extent is exact once every child is measured',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          controller: controller,
          crossAxisCount: 3,
          itemCount: 40,
          itemBuilder: (context, i) => box(i, height: heightOf(i)),
        ),
      ));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      var bottom = 0.0;
      for (var i = 0; i < 40; i++) {
        if (isBuilt(i) && rectOf(tester, i).bottom > bottom) {
          bottom = rectOf(tester, i).bottom;
        }
      }
      expect(bottom, closeTo(600, 0.001));
    });
  });

  group('SliverMasonryGrid stability', () {
    testWidgets('scrolling back up reproduces the same positions',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        MasonryGridView.count(
          controller: controller,
          crossAxisCount: 3,
          itemCount: 500,
          itemBuilder: (context, i) => box(i, height: heightOf(i)),
        ),
      ));
      final before = {for (var i = 0; i < 12; i++) i: rectOf(tester, i)};
      for (var offset = 0.0; offset < 8000; offset += 350) {
        controller.jumpTo(offset);
        await tester.pump();
      }
      for (var offset = 8000.0; offset >= 0; offset -= 350) {
        controller.jumpTo(offset);
        await tester.pump();
        expect(controller.offset, offset, reason: 'no correction at $offset');
      }
      controller.jumpTo(0);
      await tester.pump();
      for (final entry in before.entries) {
        expect(rectOf(tester, entry.key), entry.value);
      }
    });

    testWidgets('no jumps when scrolling up after items resized off-screen',
        (tester) async {
      final controller = ScrollController();
      final grow = <int>{};
      Widget build() => frame(
            MasonryGridView.count(
              controller: controller,
              cacheExtent: 0,
              crossAxisCount: 3,
              itemCount: 400,
              itemBuilder: (context, i) =>
                  box(i, height: heightOf(i) + (grow.contains(i) ? 45 : 0)),
            ),
          );
      await tester.pumpWidget(build());
      for (var offset = 0.0; offset <= 4000; offset += 300) {
        controller.jumpTo(offset);
        await tester.pump();
      }
      // Every child above the viewport changes size while disposed.
      final firstVisible =
          List<int>.generate(400, (i) => i).firstWhere(isBuilt);
      grow.addAll(List<int>.generate(firstVisible, (i) => i));
      await tester.pumpWidget(build());

      // Track the last visible child and scroll up in small steps.
      var tracked = List<int>.generate(400, (i) => i).lastWhere(isBuilt);
      var lastTop = rectOf(tester, tracked).top;
      for (var step = 0; step < 150; step++) {
        final target = controller.offset - 20;
        if (target < 600) break;
        controller.jumpTo(target);
        await tester.pump();
        if (!isBuilt(tracked) || rectOf(tester, tracked).top > 560) {
          tracked = List<int>.generate(400, (i) => i)
              .lastWhere((i) => isBuilt(i) && rectOf(tester, i).top < 400);
          lastTop = rectOf(tester, tracked).top;
          continue;
        }
        final top = rectOf(tester, tracked).top;
        expect(top - lastTop, closeTo(20, 0.001),
            reason: 'child $tracked jumped at step $step');
        lastTop = top;
      }
    });

    testWidgets('a child growing on screen keeps every column assignment',
        (tester) async {
      final tall = <int>{};
      Widget build() => frame(
            MasonryGridView.count(
              crossAxisCount: 3,
              itemCount: 30,
              itemBuilder: (context, i) =>
                  box(i, height: heightOf(i) + (tall.contains(i) ? 200 : 0)),
            ),
          );
      await tester.pumpWidget(build());
      final before = {for (var i = 0; i < 12; i++) i: rectOf(tester, i)};
      tall.add(1);
      await tester.pumpWidget(build());
      final column1 = before[1]!.left;
      for (var i = 0; i < 12; i++) {
        if (!isBuilt(i)) continue;
        final now = rectOf(tester, i);
        expect(now.left, before[i]!.left, reason: 'child $i changed column');
        if (i > 1 && now.left == column1) {
          expect(now.top, before[i]!.top + 200);
        } else if (i != 1) {
          expect(now.top, before[i]!.top);
        }
      }
    });

    testWidgets('two masonry grids in one scroll view do not jump',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        CustomScrollView(controller: controller, slivers: [
          SliverMasonryGrid.count(
            crossAxisCount: 2,
            childCount: 60,
            itemBuilder: (context, i) => box(i, height: heightOf(i)),
          ),
          SliverMasonryGrid.count(
            crossAxisCount: 3,
            childCount: 60,
            itemBuilder: (context, i) => box(1000 + i, height: heightOf(i)),
          ),
        ]),
      ));
      for (var offset = 0.0; offset < 4000; offset += 120) {
        final target =
            offset.clamp(0.0, controller.position.maxScrollExtent).toDouble();
        controller.jumpTo(target);
        await tester.pump();
        expect(controller.offset, target);
      }
      for (var offset = controller.offset; offset > 0; offset -= 120) {
        controller.jumpTo(offset);
        await tester.pump();
        expect(controller.offset, offset);
      }
    });

    testWidgets('changing the column count keeps the visible child in view',
        (tester) async {
      final controller = ScrollController();
      Widget build(int count) => frame(
            MasonryGridView.count(
              controller: controller,
              crossAxisCount: count,
              itemCount: 300,
              itemBuilder: (context, i) => box(i, height: heightOf(i)),
            ),
          );
      await tester.pumpWidget(build(2));
      controller.jumpTo(3000);
      await tester.pump();
      final anchor = List<int>.generate(300, (i) => i)
          .firstWhere((i) => isBuilt(i) && rectOf(tester, i).bottom > 0);
      await tester.pumpWidget(build(3));
      expect(isBuilt(anchor), isTrue);
      final rect = rectOf(tester, anchor);
      expect(rect.bottom, greaterThan(0));
      expect(rect.top, lessThan(600));
    });
  });

  group('SliverMasonryGrid child management', () {
    testWidgets('keeps alive children that ask for it', (tester) async {
      final controller = ScrollController();
      Widget build(bool keepAlives) => frame(
            MasonryGridView.count(
              key: ValueKey<bool>(keepAlives),
              controller: controller,
              cacheExtent: 0,
              crossAxisCount: 2,
              itemCount: 200,
              addAutomaticKeepAlives: keepAlives,
              itemBuilder: (context, i) => i == 0
                  ? const _KeepAliveItem(key: ValueKey<String>('ka'))
                  : box(i, height: 100),
            ),
          );
      await tester.pumpWidget(build(true));
      controller.jumpTo(3000);
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('ka'), skipOffstage: false),
          findsOneWidget);
      controller.jumpTo(0);
      await tester.pump();
      expect(_KeepAliveItemState.created, 1);

      await tester.pumpWidget(build(false));
      controller.jumpTo(3000);
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('ka'), skipOffstage: false),
          findsNothing);
    });

    testWidgets('addRepaintBoundaries parity', (tester) async {
      Widget build(bool value) => frame(
            MasonryGridView.count(
              key: ValueKey<bool>(value),
              crossAxisCount: 2,
              itemCount: 2,
              addRepaintBoundaries: value,
              itemBuilder: (context, i) => box(i, height: 100),
            ),
          );
      Finder boundaries() => find.ancestor(
            of: find.byKey(const ValueKey<int>(0)),
            matching: find.byType(RepaintBoundary),
          );
      await tester.pumpWidget(build(true));
      final withBoundaries = boundaries().evaluate().length;
      await tester.pumpWidget(build(false));
      expect(boundaries().evaluate().length, withBoundaries - 1);
    });

    testWidgets('insert, remove and reorder do not crash', (tester) async {
      final controller = ScrollController();
      var ids = List<int>.generate(80, (i) => i);
      Widget build() => frame(
            MasonryGridView.builder(
              controller: controller,
              gridDelegate:
                  const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
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
      controller.jumpTo(800);
      await tester.pump();

      ids = ids.reversed.toList();
      await tester.pumpWidget(build());
      ids.insertAll(0, [500, 501, 502]);
      await tester.pumpWidget(build());
      ids.removeRange(10, 40);
      await tester.pumpWidget(build());
      ids = [for (var i = 0; i < ids.length; i += 2) ids[i]];
      await tester.pumpWidget(build());
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      ids = <int>[];
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      ids = [1, 2, 3];
      await tester.pumpWidget(build());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(isBuilt(1), isTrue);
      expect(rectOf(tester, 1).top, 0);
    });

    testWidgets('shrinking the item count shrinks the scroll extent',
        (tester) async {
      final controller = ScrollController();
      Widget build(int count) => frame(
            MasonryGridView.count(
              controller: controller,
              crossAxisCount: 2,
              itemCount: count,
              itemBuilder: (context, i) => box(i, height: 100),
            ),
          );
      await tester.pumpWidget(build(100));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.pumpWidget(build(20));
      await tester.pumpAndSettle();
      expect(controller.position.maxScrollExtent, 1000 - 600);
    });
  });
}

class _KeepAliveItem extends StatefulWidget {
  const _KeepAliveItem({super.key});

  @override
  State<_KeepAliveItem> createState() => _KeepAliveItemState();
}

class _KeepAliveItemState extends State<_KeepAliveItem>
    with AutomaticKeepAliveClientMixin {
  static int created = 0;

  @override
  void initState() {
    super.initState();
    created++;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SizedBox(
        height: 100, child: Text('$created', textDirection: TextDirection.ltr));
  }
}
