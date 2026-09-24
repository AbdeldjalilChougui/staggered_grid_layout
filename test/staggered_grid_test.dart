import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout/staggered_grid_layout.dart';

import 'helpers.dart';

List<Widget> tiles() => [
      StaggeredGridTile.count(
          crossAxisCellCount: 2, mainAxisCellCount: 2, child: box(0)),
      StaggeredGridTile.count(
          crossAxisCellCount: 1, mainAxisCellCount: 1, child: box(1)),
      StaggeredGridTile.count(
          crossAxisCellCount: 1, mainAxisCellCount: 1, child: box(2)),
      StaggeredGridTile.count(
          crossAxisCellCount: 1, mainAxisCellCount: 2, child: box(3)),
      StaggeredGridTile.extent(
          crossAxisCellCount: 2, mainAxisExtent: 50, child: box(4)),
      StaggeredGridTile.fit(crossAxisCellCount: 1, child: box(5, height: 30)),
    ];

void main() {
  group('StaggeredGrid', () {
    testWidgets('places count, extent and fit tiles', (tester) async {
      await tester.pumpWidget(frame(
        width: 400,
        SingleChildScrollView(
          child: StaggeredGrid.count(crossAxisCount: 4, children: tiles()),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(200, 0, 100, 100));
      expect(rectOf(tester, 2), const Rect.fromLTWH(300, 0, 100, 100));
      expect(rectOf(tester, 3), const Rect.fromLTWH(200, 100, 100, 200));
      expect(rectOf(tester, 4), const Rect.fromLTWH(0, 200, 200, 50));
      expect(rectOf(tester, 5), const Rect.fromLTWH(300, 100, 100, 30));
      expect(tester.getSize(find.byType(StaggeredGrid)), const Size(400, 300));
    });

    testWidgets('spacing and fractional cell counts', (tester) async {
      await tester.pumpWidget(frame(
        width: 430,
        SingleChildScrollView(
          child: StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              StaggeredGridTile.count(
                  crossAxisCellCount: 2, mainAxisCellCount: 2, child: box(0)),
              StaggeredGridTile.count(
                  crossAxisCellCount: 2, mainAxisCellCount: 1.5, child: box(1)),
              StaggeredGridTile.count(
                  crossAxisCellCount: 2, mainAxisCellCount: 1, child: box(2)),
            ],
          ),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 210, 210));
      expect(rectOf(tester, 1), const Rect.fromLTWH(220, 0, 210, 155));
      expect(rectOf(tester, 2), const Rect.fromLTWH(220, 165, 210, 100));
      expect(tester.getSize(find.byType(StaggeredGrid)).height, 265);
    });

    testWidgets('RTL mirrors the columns', (tester) async {
      await tester.pumpWidget(frame(
        width: 400,
        textDirection: TextDirection.rtl,
        SingleChildScrollView(
          child: StaggeredGrid.count(crossAxisCount: 4, children: tiles()),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(200, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 100));
      expect(rectOf(tester, 5), const Rect.fromLTWH(0, 100, 100, 30));
    });

    testWidgets('horizontal axis direction', (tester) async {
      await tester.pumpWidget(frame(
        height: 400,
        width: 800,
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: StaggeredGrid.count(
            crossAxisCount: 4,
            axisDirection: AxisDirection.right,
            children: [
              StaggeredGridTile.count(
                  crossAxisCellCount: 2, mainAxisCellCount: 2, child: box(0)),
              StaggeredGridTile.count(
                  crossAxisCellCount: 1, mainAxisCellCount: 1, child: box(1)),
              StaggeredGridTile.fit(
                  crossAxisCellCount: 1, child: box(2, width: 70)),
            ],
          ),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 200, 200));
      expect(rectOf(tester, 1), const Rect.fromLTWH(0, 200, 100, 100));
      expect(rectOf(tester, 2), const Rect.fromLTWH(0, 300, 70, 100));
      expect(tester.getSize(find.byType(StaggeredGrid)), const Size(200, 400));
    });

    testWidgets('reversed main axis', (tester) async {
      await tester.pumpWidget(frame(
        width: 200,
        Align(
          alignment: Alignment.topLeft,
          child: StaggeredGrid.count(
            crossAxisCount: 2,
            axisDirection: AxisDirection.up,
            children: [
              StaggeredGridTile.count(
                  crossAxisCellCount: 1, mainAxisCellCount: 1, child: box(0)),
              StaggeredGridTile.count(
                  crossAxisCellCount: 1, mainAxisCellCount: 2, child: box(1)),
            ],
          ),
        ),
      ));
      // The grid is 200 tall and grows from the bottom.
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 100, 100, 100));
      expect(rectOf(tester, 1), const Rect.fromLTWH(100, 0, 100, 200));
    });

    testWidgets('extent constructor and unwrapped children', (tester) async {
      await tester.pumpWidget(frame(
        width: 300,
        SingleChildScrollView(
          child: StaggeredGrid.extent(
            maxCrossAxisExtent: 100,
            children: [
              box(0, height: 40),
              box(1, height: 70),
              box(2, height: 10)
            ],
          ),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 100, 40));
      expect(rectOf(tester, 2), const Rect.fromLTWH(200, 0, 100, 10));
    });

    testWidgets('tiles wider than the grid are clamped', (tester) async {
      await tester.pumpWidget(frame(
        width: 300,
        SingleChildScrollView(
          child: StaggeredGrid.count(crossAxisCount: 3, children: [
            StaggeredGridTile.count(
                crossAxisCellCount: 7, mainAxisCellCount: 1, child: box(0)),
          ]),
        ),
      ));
      expect(rectOf(tester, 0), const Rect.fromLTWH(0, 0, 300, 100));
    });

    testWidgets('supports intrinsic sizing', (tester) async {
      await tester.pumpWidget(frame(
        width: 300,
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: IntrinsicHeight(
              child: StaggeredGrid.count(crossAxisCount: 3, children: [
                StaggeredGridTile.count(
                    crossAxisCellCount: 3, mainAxisCellCount: 1, child: box(0)),
                StaggeredGridTile.fit(
                    crossAxisCellCount: 1, child: box(1, height: 45)),
              ]),
            ),
          ),
        ),
      ));
      expect(tester.getSize(find.byType(StaggeredGrid)).height, 145);
    });

    testWidgets('updates when tiles change', (tester) async {
      var span = 1;
      Widget build() => frame(
            width: 300,
            SingleChildScrollView(
              child: StaggeredGrid.count(crossAxisCount: 3, children: [
                StaggeredGridTile.count(
                    crossAxisCellCount: span,
                    mainAxisCellCount: 1,
                    child: box(0)),
                StaggeredGridTile.count(
                    crossAxisCellCount: 1, mainAxisCellCount: 1, child: box(1)),
              ]),
            ),
          );
      await tester.pumpWidget(build());
      expect(rectOf(tester, 1).topLeft, const Offset(100, 0));
      span = 3;
      await tester.pumpWidget(build());
      expect(rectOf(tester, 1).topLeft, const Offset(0, 100));
    });
  });
}
