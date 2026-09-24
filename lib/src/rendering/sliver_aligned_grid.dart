import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import 'masonry_layout_cache.dart' show kMasonryTolerance;
import 'sliver_child_walker.dart';

/// Parent data of the children of a [RenderSliverAlignedGrid].
class SliverAlignedGridParentData extends SliverMultiBoxAdaptorParentData {
  /// The offset of the child along the cross axis, from the left (vertical
  /// grids) or top (horizontal grids) edge of the sliver.
  double crossAxisOffset = 0;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// Wraps one child of an aligned grid.
///
/// The grid passes constraints whose main axis minimum is the current extent
/// of the row. The cell first measures its child without that minimum and
/// remembers the result as [naturalExtent], then stretches the child to the
/// row extent. Because the cell only re-runs this when its constraints change
/// or its child needs layout, scrolling does not lay children out twice.
class RenderAlignedGridCell extends RenderProxyBox {
  /// Creates a cell.
  RenderAlignedGridCell({RenderBox? child}) : super(child);

  /// The main axis extent the child wants, ignoring the row extent.
  double get naturalExtent => _naturalExtent;
  double _naturalExtent = 0;

  @override
  void performLayout() {
    final constraints = this.constraints;
    // The grid leaves the main axis unbounded.
    final vertical = !constraints.hasBoundedHeight;
    final child = this.child;
    if (child == null) {
      _naturalExtent = 0;
      size = constraints.smallest;
      return;
    }
    final loose = vertical
        ? BoxConstraints(
            minWidth: constraints.minWidth, maxWidth: constraints.maxWidth)
        : BoxConstraints(
            minHeight: constraints.minHeight, maxHeight: constraints.maxHeight);
    child.layout(loose, parentUsesSize: true);
    _naturalExtent = vertical ? child.size.height : child.size.width;
    final rowExtent = vertical ? constraints.minHeight : constraints.minWidth;
    if (_naturalExtent < rowExtent) {
      child.layout(
        vertical
            ? BoxConstraints.tightFor(
                width: child.size.width, height: rowExtent)
            : BoxConstraints.tightFor(
                width: rowExtent, height: child.size.height),
        parentUsesSize: true,
      );
    }
    size = constraints.constrain(child.size);
  }
}

/// A sliver that places children in rows; each row is as tall as its
/// tallest child and every child of the row is stretched to that extent.
///
/// Row extents are cached by row index so that scrolling back up reuses the
/// layout computed on the way down. When a row that starts above the viewport
/// changes extent, the scroll offset is corrected so that content on screen
/// does not move.
class RenderSliverAlignedGrid extends RenderSliverMultiBoxAdaptor
    with SliverChildWalker {
  /// Creates an aligned grid sliver.
  RenderSliverAlignedGrid({
    required super.childManager,
    required SliverSimpleGridDelegate gridDelegate,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    int? childCountHint,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        _gridDelegate = gridDelegate,
        _mainAxisSpacing = mainAxisSpacing,
        _crossAxisSpacing = crossAxisSpacing,
        _childCountHint = childCountHint;

  /// Decides the number of tracks per row.
  SliverSimpleGridDelegate get gridDelegate => _gridDelegate;
  SliverSimpleGridDelegate _gridDelegate;
  set gridDelegate(SliverSimpleGridDelegate value) {
    if (identical(_gridDelegate, value)) return;
    if (value.runtimeType != _gridDelegate.runtimeType ||
        value.shouldRelayout(_gridDelegate)) {
      markNeedsLayout();
    }
    _gridDelegate = value;
  }

  /// The space between two rows.
  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  /// The space between two children of a row.
  double get crossAxisSpacing => _crossAxisSpacing;
  double _crossAxisSpacing;
  set crossAxisSpacing(double value) {
    if (_crossAxisSpacing == value) return;
    _crossAxisSpacing = value;
    markNeedsLayout();
  }

  /// The number of children when known in advance, otherwise null.
  int? get childCountHint => _childCountHint;
  int? _childCountHint;
  set childCountHint(int? value) {
    if (_childCountHint == value) return;
    _childCountHint = value;
    markNeedsLayout();
  }

  // Row cache: offsets and extents of rows 0..length-1.
  final List<double> _rowOffsets = <double>[];
  final List<double> _rowExtents = <double>[];
  int _cachedCount = 0;
  double _cachedCrossExtent = -1;
  double _cachedSpacing = -1;

  late int _count;
  late double _childCrossAxisExtent;
  late Axis _axis;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverAlignedGridParentData) {
      child.parentData = SliverAlignedGridParentData();
    }
  }

  @override
  double childCrossAxisPosition(RenderBox child) =>
      (child.parentData! as SliverAlignedGridParentData).crossAxisOffset;

  @override
  BoxConstraints childConstraintsFor(int index) {
    final row = index ~/ _count;
    final minMain = row < _rowExtents.length ? _rowExtents[row] : 0.0;
    return _axis == Axis.vertical
        ? BoxConstraints(
            minWidth: _childCrossAxisExtent,
            maxWidth: _childCrossAxisExtent,
            minHeight: minMain,
          )
        : BoxConstraints(
            minHeight: _childCrossAxisExtent,
            maxHeight: _childCrossAxisExtent,
            minWidth: minMain,
          );
  }

  @override
  void didLayoutChild(RenderBox child) {}

  double _naturalExtentOf(RenderBox child) {
    RenderObject? node = child;
    while (node is RenderObjectWithChildMixin<RenderBox>) {
      if (node is RenderAlignedGridCell) return node.naturalExtent;
      node = node.child;
    }
    return _axis == Axis.vertical ? child.size.height : child.size.width;
  }

  double _rowTrailing(int row) => _rowOffsets[row] + _rowExtents[row];

  double get _nextRowOffset => _rowOffsets.isEmpty
      ? 0
      : _rowTrailing(_rowOffsets.length - 1) + _mainAxisSpacing;

  void _truncateRows(int length) {
    if (length >= _rowOffsets.length) return;
    _rowOffsets.removeRange(math.max(0, length), _rowOffsets.length);
    _rowExtents.removeRange(math.max(0, length), _rowExtents.length);
  }

  /// Lays out every child of [row]. Returns the number of children in the
  /// row (0 when the row does not exist) and updates the row cache.
  ///
  /// Returns the extent change of a row that already existed.
  ({int children, double delta}) _layoutRow(int row) {
    final start = row * _count;
    var extent = 0.0;
    var children = 0;
    for (var i = 0; i < _count; i++) {
      final child = obtainChild(start + i);
      if (child == null) break;
      children++;
      extent = math.max(extent, _naturalExtentOf(child));
    }
    if (children == 0) return (children: 0, delta: 0);
    var delta = 0.0;
    if (row < _rowExtents.length) {
      delta = extent - _rowExtents[row];
      if (delta.abs() <= kMasonryTolerance) {
        delta = 0;
      } else {
        _rowExtents[row] = extent;
        for (var r = row + 1; r < _rowOffsets.length; r++) {
          _rowOffsets[r] += delta;
        }
      }
    } else {
      _rowOffsets.add(_nextRowOffset);
      _rowExtents.add(extent);
    }
    // Stretch the children to the row extent.
    RenderBox? child = firstChild;
    while (child != null && indexOf(child) < start) {
      child = childAfter(child);
    }
    while (child != null && indexOf(child) < start + children) {
      child.layout(childConstraintsFor(indexOf(child)), parentUsesSize: true);
      child = childAfter(child);
    }
    return (children: children, delta: delta);
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    _axis = constraints.axis;
    _count = _gridDelegate.getCrossAxisCount(
        constraints.crossAxisExtent, _crossAxisSpacing);
    _childCrossAxisExtent = _gridDelegate.getChildCrossAxisExtent(
        constraints.crossAxisExtent, _crossAxisSpacing);

    int? anchorIndex;
    double anchorOffset = 0;
    if (_count != _cachedCount ||
        (_childCrossAxisExtent - _cachedCrossExtent).abs() >
            kMasonryTolerance ||
        _mainAxisSpacing != _cachedSpacing) {
      if (firstChild != null && _rowOffsets.isNotEmpty && _cachedCount > 0) {
        for (var r = 0; r < _rowOffsets.length; r++) {
          if (_rowTrailing(r) > constraints.scrollOffset) {
            anchorIndex = r * _cachedCount;
            anchorOffset = _rowOffsets[r];
            break;
          }
        }
      }
      _rowOffsets.clear();
      _rowExtents.clear();
      _cachedCount = _count;
      _cachedCrossExtent = _childCrossAxisExtent;
      _cachedSpacing = _mainAxisSpacing;
    }
    final hint = _childCountHint;
    if (hint != null) _truncateRows((hint + _count - 1) ~/ _count);

    final scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    final targetEnd = scrollOffset + constraints.remainingCacheExtent;
    var reachedEnd = false;

    bool rowsExhausted() => hint != null && _rowOffsets.length * _count >= hint;

    // 1. Measure rows that were never laid out, until the cache reaches the
    //    first needed row (or the anchor row after a track change).
    final anchorRow = anchorIndex == null ? null : anchorIndex ~/ _count;
    while (!reachedEnd &&
        !rowsExhausted() &&
        (_rowOffsets.isEmpty ||
            (anchorRow != null && _rowOffsets.length <= anchorRow) ||
            (anchorRow == null &&
                _rowTrailing(_rowOffsets.length - 1) <= scrollOffset))) {
      final row = _rowOffsets.length;
      final keep =
          lastChild != null && indexOf(lastChild!) == row * _count - 1 ? 1 : 0;
      collectGarbage(countChildren() - keep, 0);
      if (_layoutRow(row).children < _count) {
        reachedEnd = true;
        _truncateRows(row + (_rowOffsets.length > row ? 1 : 0));
      }
    }

    if (anchorRow != null && anchorRow < _rowOffsets.length) {
      final correction = math.max(
        _rowOffsets[anchorRow] - anchorOffset,
        -constraints.scrollOffset,
      );
      if (correction.abs() > kMasonryTolerance) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        childManager.didFinishLayout();
        return;
      }
    }

    // 2. Lay out the rows that intersect the target range.
    var firstRow = _rowOffsets.length;
    for (var r = 0; r < _rowOffsets.length; r++) {
      if (_rowTrailing(r) > scrollOffset + kMasonryTolerance) {
        firstRow = r;
        break;
      }
    }
    if (firstRow == _rowOffsets.length && _rowOffsets.isNotEmpty) {
      // Scrolled past the end: keep the last row so the grid stays anchored.
      firstRow = _rowOffsets.length - 1;
    }
    collectGarbage(countChildrenBefore(firstRow * _count), 0);

    var correction = 0.0;
    var row = firstRow;
    var lastRow = firstRow - 1;
    while (true) {
      final offset =
          row < _rowOffsets.length ? _rowOffsets[row] : _nextRowOffset;
      if (row != firstRow && offset >= targetEnd) break;
      if (rowsExhausted() && row >= _rowOffsets.length) break;
      final result = _layoutRow(row);
      if (result.children == 0) {
        reachedEnd = true;
        _truncateRows(row);
        break;
      }
      if (result.delta != 0 &&
          _rowOffsets[row] < constraints.scrollOffset - kMasonryTolerance) {
        correction += result.delta;
      }
      lastRow = row;
      row++;
      if (result.children < _count) {
        reachedEnd = true;
        _truncateRows(row);
        break;
      }
    }
    collectGarbage(0, countChildrenAfter((lastRow + 1) * _count - 1));

    if (correction != 0) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: math.max(correction, -constraints.scrollOffset),
      );
      childManager.didFinishLayout();
      return;
    }

    // 3. Position the children.
    final reverseCrossAxis =
        axisDirectionIsReversed(constraints.crossAxisDirection);
    final stride = _childCrossAxisExtent + _crossAxisSpacing;
    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      final index = indexOf(child);
      final data = child.parentData! as SliverAlignedGridParentData;
      final r = index ~/ _count;
      data.layoutOffset = r < _rowOffsets.length ? _rowOffsets[r] : 0;
      final cross = (index % _count) * stride;
      data.crossAxisOffset = reverseCrossAxis
          ? constraints.crossAxisExtent - cross - _childCrossAxisExtent
          : cross;
    }

    final leading =
        firstChild == null || lastRow < firstRow ? 0.0 : _rowOffsets[firstRow];
    final trailing =
        firstChild == null || lastRow < firstRow ? 0.0 : _rowTrailing(lastRow);
    final lastTrailing =
        _rowOffsets.isEmpty ? 0.0 : _rowTrailing(_rowOffsets.length - 1);
    final exact = reachedEnd || rowsExhausted();
    final double scrollExtent;
    if (exact) {
      scrollExtent = lastTrailing;
    } else if (hint == null) {
      scrollExtent = double.infinity;
    } else {
      final remainingRows = (hint + _count - 1) ~/ _count - _rowOffsets.length;
      var sum = 0.0;
      for (final extent in _rowExtents) {
        sum += extent;
      }
      final average = _rowExtents.isEmpty ? 0.0 : sum / _rowExtents.length;
      scrollExtent =
          lastTrailing + remainingRows * (average + _mainAxisSpacing);
    }

    final paintExtent = calculatePaintOffset(
      constraints,
      from: math.min(constraints.scrollOffset, leading),
      to: trailing,
    );
    final cacheExtent =
        calculateCacheOffset(constraints, from: leading, to: trailing);
    geometry = SliverGeometry(
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      maxPaintExtent: scrollExtent,
      cacheExtent: cacheExtent,
      hasVisualOverflow: scrollExtent > paintExtent ||
          constraints.scrollOffset > 0.0 ||
          constraints.overlap != 0.0,
    );
    if (exact && trailing >= scrollExtent - kMasonryTolerance) {
      childManager.setDidUnderflow(true);
    }
    childManager.didFinishLayout();
  }
}
