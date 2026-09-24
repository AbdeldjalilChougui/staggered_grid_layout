import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../delegates/sliver_simple_grid_delegate.dart';

/// Parent data of the children of a [RenderStaggeredGrid].
class StaggeredGridParentData extends ContainerBoxParentData<RenderBox> {
  /// Number of columns the child spans. Defaults to 1.
  int crossAxisCellCount = 1;

  /// Number of cells along the main axis, for count tiles.
  num? mainAxisCellCount;

  /// Fixed main axis extent, for extent tiles.
  double? mainAxisExtent;

  @override
  String toString() => 'crossAxisCellCount=$crossAxisCellCount; '
      'mainAxisCellCount=$mainAxisCellCount; mainAxisExtent=$mainAxisExtent; '
      '${super.toString()}';
}

/// A non-scrolling box that places tiles in the group of columns whose
/// content ends first.
///
/// A tile spanning `k` columns is placed at the start column `s` that
/// minimizes the highest end among columns `s..s+k-1`; ties go to the lowest
/// `s`. Tiles sized in cells are square-celled: a cell is as long along the
/// main axis as it is wide.
class RenderStaggeredGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, StaggeredGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, StaggeredGridParentData> {
  /// Creates a staggered grid.
  RenderStaggeredGrid({
    required SliverSimpleGridDelegate delegate,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    AxisDirection axisDirection = AxisDirection.down,
    TextDirection textDirection = TextDirection.ltr,
  })  : _delegate = delegate,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _axisDirection = axisDirection,
        _textDirection = textDirection;

  /// Decides the number of columns.
  SliverSimpleGridDelegate get delegate => _delegate;
  SliverSimpleGridDelegate _delegate;
  set delegate(SliverSimpleGridDelegate value) {
    if (identical(_delegate, value)) return;
    if (value.runtimeType != _delegate.runtimeType ||
        value.shouldRelayout(_delegate)) {
      markNeedsLayout();
    }
    _delegate = value;
  }

  /// Space between tiles along the main axis.
  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  /// Space between columns.
  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  /// The direction in which the main axis grows.
  AxisDirection get axisDirection => _axisDirection;
  AxisDirection _axisDirection;
  set axisDirection(AxisDirection value) {
    if (_axisDirection == value) return;
    _axisDirection = value;
    markNeedsLayout();
  }

  /// Reading direction, used to order columns of a vertical grid.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Axis get _mainAxis => axisDirectionToAxis(_axisDirection);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StaggeredGridParentData) {
      child.parentData = StaggeredGridParentData();
    }
  }

  /// Runs the placement algorithm.
  ///
  /// [measure] returns the main axis extent of a `fit` child given its cross
  /// axis extent. [place] receives every child with its main axis offset,
  /// main axis extent, cross axis offset and cross axis extent. Returns the
  /// total main axis extent.
  double _run(
    double crossAxisExtent,
    double Function(RenderBox child, double crossExtent) measure, [
    void Function(RenderBox child, double mainOffset, double mainExtent,
            double crossOffset, double crossExtent)?
        place,
  ]) {
    final count =
        _delegate.getCrossAxisCount(crossAxisExtent, _crossAxisSpacing);
    final cell =
        _delegate.getChildCrossAxisExtent(crossAxisExtent, _crossAxisSpacing);
    final ends = List<double>.filled(count, 0);
    var total = 0.0;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as StaggeredGridParentData;
      final span = data.crossAxisCellCount.clamp(1, count);
      final tileCross = span * cell + (span - 1) * _crossAxisSpacing;

      var start = 0;
      var offset = double.infinity;
      for (var s = 0; s + span <= count; s++) {
        var top = 0.0;
        for (var c = s; c < s + span; c++) {
          top = math.max(top, ends[c]);
        }
        if (top < offset - 1e-7) {
          offset = top;
          start = s;
        }
      }

      final double extent;
      final cells = data.mainAxisCellCount;
      if (cells != null) {
        extent = cells * cell + (cells - 1) * _mainAxisSpacing;
      } else if (data.mainAxisExtent != null) {
        extent = data.mainAxisExtent!;
      } else {
        extent = measure(child, tileCross);
      }
      final safeExtent = math.max(0.0, extent);
      for (var c = start; c < start + span; c++) {
        ends[c] = offset + safeExtent + _mainAxisSpacing;
      }
      total = math.max(total, offset + safeExtent);
      place?.call(child, offset, safeExtent, start * (cell + _crossAxisSpacing),
          tileCross);
      child = data.nextSibling;
    }
    return total;
  }

  BoxConstraints _tight(double main, double cross) => _mainAxis == Axis.vertical
      ? BoxConstraints.tightFor(width: cross, height: main)
      : BoxConstraints.tightFor(width: main, height: cross);

  BoxConstraints _fit(double cross) => _mainAxis == Axis.vertical
      ? BoxConstraints.tightFor(width: cross)
      : BoxConstraints.tightFor(height: cross);

  double _crossExtentOf(BoxConstraints constraints) {
    final value = _mainAxis == Axis.vertical
        ? constraints.maxWidth
        : constraints.maxHeight;
    assert(
      value.isFinite,
      'StaggeredGrid needs a bounded cross axis extent. Give it a width (or a '
      'height when its main axis is horizontal).',
    );
    return value.isFinite ? value : 0;
  }

  Size _sizeFor(BoxConstraints constraints, double cross, double main) =>
      constraints.constrain(
          _mainAxis == Axis.vertical ? Size(cross, main) : Size(main, cross));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final cross = _crossExtentOf(constraints);
    final main = _run(cross, (child, crossExtent) {
      final size = child.getDryLayout(_fit(crossExtent));
      return _mainAxis == Axis.vertical ? size.height : size.width;
    });
    return _sizeFor(constraints, cross, main);
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    final cross = _crossExtentOf(constraints);
    final placements = <RenderBox, (double, double, double, double)>{};
    final main = _run(cross, (child, crossExtent) {
      child.layout(_fit(crossExtent), parentUsesSize: true);
      return _mainAxis == Axis.vertical ? child.size.height : child.size.width;
    }, (child, mainOffset, mainExtent, crossOffset, crossExtent) {
      placements[child] = (mainOffset, mainExtent, crossOffset, crossExtent);
    });
    size = _sizeFor(constraints, cross, main);
    final mainSize = _mainAxis == Axis.vertical ? size.height : size.width;
    final crossSize = _mainAxis == Axis.vertical ? size.width : size.height;
    final reverseMain = axisDirectionIsReversed(_axisDirection);
    final reverseCross =
        _mainAxis == Axis.vertical && _textDirection == TextDirection.rtl;

    placements.forEach((child, p) {
      final (mainOffset, mainExtent, crossOffset, crossExtent) = p;
      final data = child.parentData! as StaggeredGridParentData;
      if (data.mainAxisCellCount != null || data.mainAxisExtent != null) {
        child.layout(_tight(mainExtent, crossExtent));
      }
      final m = reverseMain ? mainSize - mainOffset - mainExtent : mainOffset;
      final c =
          reverseCross ? crossSize - crossOffset - crossExtent : crossOffset;
      data.offset = _mainAxis == Axis.vertical ? Offset(c, m) : Offset(m, c);
    });
  }

  double _intrinsicMain(double cross) {
    if (!cross.isFinite) return 0;
    return _run(cross, (child, crossExtent) {
      return _mainAxis == Axis.vertical
          ? child.getMaxIntrinsicHeight(crossExtent)
          : child.getMaxIntrinsicWidth(crossExtent);
    });
  }

  double _intrinsicCross(double main) {
    // The widest child, scaled up to the number of columns it spans.
    var result = 0.0;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as StaggeredGridParentData;
      final width = _mainAxis == Axis.vertical
          ? child.getMaxIntrinsicWidth(double.infinity)
          : child.getMaxIntrinsicHeight(double.infinity);
      result =
          math.max(result, width / data.crossAxisCellCount.clamp(1, 1 << 20));
      child = data.nextSibling;
    }
    final delegate = _delegate;
    final count = delegate is SliverSimpleGridDelegateWithFixedCrossAxisCount
        ? delegate.crossAxisCount
        : 1;
    return result * count + _crossAxisSpacing * (count - 1);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _mainAxis == Axis.vertical
      ? _intrinsicMain(width)
      : _intrinsicCross(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double computeMinIntrinsicWidth(double height) => _mainAxis == Axis.vertical
      ? _intrinsicCross(height)
      : _intrinsicMain(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      computeMinIntrinsicWidth(height);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
