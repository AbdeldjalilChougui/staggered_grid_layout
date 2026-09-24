import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in a fixed-size, directional box at the top-left corner.
Widget frame(
  Widget child, {
  double width = 300,
  double height = 600,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, height: height, child: child),
      ),
    ),
  );
}

/// A colored box with a key derived from [index].
Widget box(int index, {double? width, double? height}) {
  return SizedBox(
    key: ValueKey<int>(index),
    width: width,
    height: height,
    child: Text('$index', textDirection: TextDirection.ltr),
  );
}

/// The rectangle of the item with the given [index] key.
Rect rectOf(WidgetTester tester, int index) =>
    tester.getRect(find.byKey(ValueKey<int>(index), skipOffstage: false));

/// Whether the item with the given [index] key is currently built.
bool isBuilt(int index) =>
    find.byKey(ValueKey<int>(index), skipOffstage: false).evaluate().isNotEmpty;
