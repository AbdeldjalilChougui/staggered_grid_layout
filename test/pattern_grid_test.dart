import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout/staggered_grid_layout.dart';

import 'helpers.dart';

const _pattern = <QuiltedGridTile>[
  QuiltedGridTile(2, 2),
  QuiltedGridTile(1, 1),
  QuiltedGridTile(1, 1),
  QuiltedGridTile(1, 2),
];

Widget quilted({
  int count = 12,
  QuiltedGridRepeatPattern repeat = QuiltedGridRepeatPattern.same,
  double mainAxisSpacing = 0,
  double crossAxisSpacing = 0,
  List<QuiltedGridTile> pattern = _pattern,
  int crossAxisCount = 4,
  Axis scrollDirection = Axis.vertical,
  ScrollController? controller,
}) {
  return CustomScrollView(
    controller: controller,
    scrollDirection: scrollDirection,
    slivers: [
      SliverQuiltedGrid.builder(
        crossAxisCount: crossAxisCount,
        pattern: pattern,
        repeatPattern: repeat,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        itemCount: count,
        itemBuilder: (context, i) => box(i),
      ),
    ],
  );
}

void main() {
  group('SliverQuiltedGrid', () {
    testWidgets('places the pattern tiles', (tester) async {
      await tester.pumpWidget(frame(width: 400, quilted()));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(200, 0, 100, 100));
      expect(rectOf(tester, 2), const Rect.fromLTWH(300, 0, 100, 100));
      expect(rectOf(tester, 3), const Rect.fromLTWH(200, 100, 200, 100));
      // The pattern repeats below.
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 200, 200, 200));
      expect(rectOf(tester, 7), const Rect.fromLTWH(200, 300, 200, 100));
      expect(rectOf(tester, 8), const Rect.fromLTWH(0, 400, 200, 200));
    });

    testWidgets('mirrored repeat flips every other block', (tester) async {
      await tester.pumpWidget(frame(
          width: 400, quilted(repeat: QuiltedGridRepeatPattern.mirrored)));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 200));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 200, 100, 100));
      expect(rectOf(tester, 5), const Rect.fromLTWH(100, 200, 100, 100));
      expect(rectOf(tester, 6), const Rect.fromLTWH(200, 200, 200, 200));
      expect(rectOf(tester, 7), const Rect.fromLTWH(0, 300, 200, 100));
      expect(rectOf(tester, 8), const Rect.fromLTWH(0, 400, 200, 200));
    });

    testWidgets('inverted repeat rotates every other block', (tester) async {
      await tester.pumpWidget(frame(
          width: 400, quilted(repeat: QuiltedGridRepeatPattern.inverted)));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 200, 200, 100));
      expect(rectOf(tester, 5), const Rect.fromLTWH(200, 200, 200, 200));
      expect(rectOf(tester, 6), const Rect.fromLTWH(0, 300, 100, 100));
      expect(rectOf(tester, 7), const Rect.fromLTWH(100, 300, 100, 100));
      expect(rectOf(tester, 8), const Rect.fromLTWH(0, 400, 200, 200));
    });

    testWidgets('spacing', (tester) async {
      await tester.pumpWidget(frame(
        width: 430,
        quilted(mainAxisSpacing: 10, crossAxisSpacing: 10),
      ));
      // Cells are (430 - 3 * 10) / 4 = 100.
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 210, 210));
      expect(rectOf(tester, 2), const Rect.fromLTWH(330, 0, 100, 100));
      expect(rectOf(tester, 3), const Rect.fromLTWH(220, 110, 210, 100));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 220, 210, 210));
    });

    testWidgets('RTL mirrors the cross axis', (tester) async {
      await tester.pumpWidget(frame(
        width: 400,
        textDirection: TextDirection.rtl,
        quilted(),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(200, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 100));
      expect(rectOf(tester, 3), const Rect.fromLTWH(0, 100, 200, 100));
    });

    testWidgets('horizontal axis', (tester) async {
      await tester.pumpWidget(frame(
        height: 400,
        quilted(scrollDirection: Axis.horizontal),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 200, 100, 100));
      expect(rectOf(tester, 3), const Rect.fromLTWH(100, 200, 100, 200));
      expect(rectOf(tester, 4), const Rect.fromLTWH(200, 0, 200, 200));
    });

    testWidgets('does not scroll past the last child', (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        width: 400,
        height: 300,
        quilted(count: 10, controller: controller),
      ));
      // Item 8 is the big tile of the third block, ending at 600.
      expect(controller.position.maxScrollExtent, 300);
    });

    testWidgets('tiles that do not fit the first free cell move down',
        (tester) async {
      await tester.pumpWidget(frame(
        quilted(
          crossAxisCount: 3,
          count: 6,
          pattern: const [
            QuiltedGridTile(1, 1),
            QuiltedGridTile(1, 1),
            QuiltedGridTile(2, 2),
          ],
        ),
      ));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 100, 200, 200));
      // Block height is 3 cells.
      expect(rectOf(tester, 3), const Rect.fromLTWH(0, 300, 100, 100));
    });

    testWidgets('builds lazily', (tester) async {
      final built = <int>{};
      await tester.pumpWidget(frame(
        width: 400,
        CustomScrollView(cacheExtent: 0, slivers: [
          SliverQuiltedGrid.builder(
            crossAxisCount: 4,
            pattern: _pattern,
            itemCount: 10000,
            itemBuilder: (context, i) {
              built.add(i);
              return box(i);
            },
          ),
        ]),
      ));
      // Three blocks of 200 fill 600.
      expect(built, {for (var i = 0; i < 12; i++) i});
    });

    testWidgets('scrolls through spaced, repeated blocks without errors',
        (tester) async {
      final controller = ScrollController();
      await tester.pumpWidget(frame(
        width: 430,
        quilted(
          count: 500,
          controller: controller,
          repeat: QuiltedGridRepeatPattern.inverted,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
      ));
      for (var offset = 0.0; offset < 40000; offset += 137) {
        controller.jumpTo(
            offset.clamp(0.0, controller.position.maxScrollExtent).toDouble());
        await tester.pump();
      }
      expect(isBuilt(499), isTrue);
      expect(controller.position.maxScrollExtent,
          rectOf(tester, 499).bottom + controller.offset - 600);
    });

    testWidgets('delegate works with GridView.custom', (tester) async {
      await tester.pumpWidget(frame(
        width: 400,
        GridView.custom(
          gridDelegate: SliverQuiltedGridDelegate(
            crossAxisCount: 4,
            pattern: _pattern,
          ),
          childrenDelegate: SliverChildBuilderDelegate(
            (context, i) => box(i),
            childCount: 4,
          ),
        ),
      ));
      expect(rectOf(tester, 3), const Rect.fromLTWH(200, 100, 200, 100));
    });
  });

  group('SliverWovenGrid', () {
    Widget woven({
      List<WovenGridTile> pattern = const [
        WovenGridTile(1),
        WovenGridTile(0.5),
      ],
      Axis scrollDirection = Axis.vertical,
      double tileBottomSpace = 0,
    }) {
      return CustomScrollView(scrollDirection: scrollDirection, slivers: [
        SliverWovenGrid.count(
          crossAxisCount: 2,
          pattern: pattern,
          tileBottomSpace: tileBottomSpace,
          delegate: SliverChildBuilderDelegate(
            (context, i) => box(i),
            childCount: 8,
          ),
        ),
      ]);
    }

    testWidgets('weaves the pattern across two tracks', (tester) async {
      await tester.pumpWidget(frame(width: 200, woven()));
      // Tracks are 200 tall (the tallest tile of the pattern).
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 50, 100, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 200));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 200, 100, 200));
      expect(rectOf(tester, 3), const Rect.fromLTWH(100, 250, 100, 100));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 450, 100, 100));
    });

    testWidgets('cross axis ratio, alignment and RTL', (tester) async {
      const pattern = [
        WovenGridTile(
          1,
          crossAxisRatio: 0.8,
          alignment: AlignmentDirectional.centerEnd,
        ),
      ];
      await tester.pumpWidget(frame(width: 200, woven(pattern: pattern)));
      // Track extent is 80; the first track aligns to the end, the second
      // to the start.
      expect(rectOf(tester, 0), const Rect.fromLTWH(20, 0, 80, 80));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 80, 80, 80));

      await tester.pumpWidget(frame(
        width: 200,
        textDirection: TextDirection.rtl,
        woven(pattern: pattern),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(100, 0, 80, 80));
    });

    testWidgets('tile bottom space', (tester) async {
      await tester.pumpWidget(frame(
          width: 200,
          woven(pattern: const [WovenGridTile(1)], tileBottomSpace: 20)));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 100, 120));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 120, 100, 120));
    });

    testWidgets('extent constructor and horizontal axis', (tester) async {
      await tester.pumpWidget(frame(
        height: 200,
        CustomScrollView(scrollDirection: Axis.horizontal, slivers: [
          SliverWovenGrid.extent(
            maxCrossAxisExtent: 100,
            pattern: const [WovenGridTile(0.5)],
            delegate: SliverChildBuilderDelegate(
              (context, i) => box(i),
              childCount: 4,
            ),
          ),
        ]),
      ));
      // Two rows of 100; aspect ratio 0.5 makes tiles 200 long.
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 100, 200, 100));
      expect(rectOf(tester, 2), const Rect.fromLTWH(200, 0, 200, 100));
    });
  });
}
