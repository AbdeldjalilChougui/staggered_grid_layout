import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import 'masonry_layout_cache.dart';
import 'sliver_child_walker.dart';

/// Parent data of the children of a [RenderSliverMasonryGrid].
class SliverMasonryGridParentData extends SliverMultiBoxAdaptorParentData {
  /// The offset of the child along the cross axis, from the left (vertical
  /// grids) or top (horizontal grids) edge of the sliver.
  double crossAxisOffset = 0;

  @override
  String toString() => 'crossAxisOffset=$crossAxisOffset; ${super.toString()}';
}

/// A sliver that places children Pinterest-style: each child goes into the
/// column whose content ends first, ties going to the lowest column.
///
/// Children size themselves along the main axis. Placements are cached by
/// index, so scrolling back up reuses exactly the layout computed on the way
/// down. When a child changes size it keeps its column; see
/// [SliverMasonryGrid] for the full resize rules.
class RenderSliverMasonryGrid extends RenderSliverMultiBoxAdaptor
    with SliverChildWalker {
  /// Creates a masonry sliver.
  RenderSliverMasonryGrid({
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

  final MasonryLayoutCache _cache = MasonryLayoutCache();

  /// Decides the number of columns.
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

  /// The space between two children of the same column.
  double get mainAxisSpacing => _mainAxisSpacing;
  double _mainAxisSpacing;
  set mainAxisSpacing(double value) {
    if (_mainAxisSpacing == value) return;
    _mainAxisSpacing = value;
    markNeedsLayout();
  }

  /// The space between two columns.
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

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverMasonryGridParentData) {
      child.parentData = SliverMasonryGridParentData();
    }
  }

  @override
  double childCrossAxisPosition(RenderBox child) =>
      (child.parentData! as SliverMasonryGridParentData).crossAxisOffset;

  late BoxConstraints _childConstraints;
  late double _childCrossAxisExtent;
  late int _crossAxisCount;
  bool _cacheChanged = false;

  double _extentOf(RenderBox child) =>
      constraints.axis == Axis.vertical ? child.size.height : child.size.width;

  @override
  BoxConstraints childConstraintsFor(int index) => _childConstraints;

  /// Compares the size of a freshly laid out child with the cache.
  @override
  void didLayoutChild(RenderBox child) {
    final index = indexOf(child);
    if (index >= _cache.length) return;
    final entry = _cache[index];
    final extent = _extentOf(child);
    if ((extent - entry.extent).abs() <= kMasonryTolerance) return;
    _cache.resize(
      index,
      extent,
      anchorTrailing:
          entry.offset < constraints.scrollOffset - kMasonryTolerance,
    );
    _cacheChanged = true;
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    _crossAxisCount = _gridDelegate.getCrossAxisCount(
        constraints.crossAxisExtent, _crossAxisSpacing);
    _childCrossAxisExtent = _gridDelegate.getChildCrossAxisExtent(
        constraints.crossAxisExtent, _crossAxisSpacing);
    _childConstraints = constraints.axis == Axis.vertical
        ? BoxConstraints.tightFor(width: _childCrossAxisExtent)
        : BoxConstraints.tightFor(height: _childCrossAxisExtent);

    // When the tracks change, every placement is recomputed. The first
    // visible child is used as an anchor so that it stays on screen.
    int? anchorIndex;
    double anchorOffset = 0;
    if (!_cache.matches(
        _crossAxisCount, _mainAxisSpacing, _childCrossAxisExtent)) {
      if (firstChild != null && _cache.length > 0) {
        for (RenderBox? child = firstChild;
            child != null;
            child = childAfter(child)) {
          final index = indexOf(child);
          if (index < _cache.length &&
              _cache[index].trailing > constraints.scrollOffset) {
            anchorIndex = index;
            anchorOffset = _cache[index].offset;
            break;
          }
        }
      }
      _cache.reset(_crossAxisCount, _mainAxisSpacing, _childCrossAxisExtent);
    }
    final hint = _childCountHint;
    if (hint != null) _cache.truncate(hint);

    final scrollOffset = constraints.scrollOffset + constraints.cacheOrigin;
    final targetEndScrollOffset =
        scrollOffset + constraints.remainingCacheExtent;

    // 1. Children that are alive keep being measured: a size change updates
    //    the cache.
    _cacheChanged = false;
    if (anchorIndex == null) {
      for (RenderBox? child = firstChild;
          child != null;
          child = childAfter(child)) {
        child.layout(_childConstraints, parentUsesSize: true);
        didLayoutChild(child);
      }
    }

    var reachedEnd = false;
    for (var pass = 0; pass < 4; pass++) {
      _cacheChanged = false;

      // 2. Extend the cache until it covers the target range.
      final extended = _extendCache(
        scrollOffset: scrollOffset,
        targetEnd: targetEndScrollOffset,
        anchorIndex: anchorIndex,
      );
      reachedEnd = reachedEnd || extended;

      if (anchorIndex != null) {
        if (anchorIndex < _cache.length) {
          final correction = math.max(
            _cache[anchorIndex].offset - anchorOffset,
            -constraints.scrollOffset,
          );
          anchorIndex = null;
          if (correction.abs() > kMasonryTolerance) {
            geometry = SliverGeometry(scrollOffsetCorrection: correction);
            childManager.didFinishLayout();
            return;
          }
        } else {
          anchorIndex = null;
        }
      }

      // 3. Make sure exactly the children that intersect the target range
      //    are alive.
      _materialize(scrollOffset, targetEndScrollOffset);

      // 4. A child that grew upward can push a column above zero: shift the
      //    whole layout and the scroll offset by the same amount, which is
      //    invisible to the user.
      final shift = _cache.normalize();
      if (shift > 0) {
        geometry = SliverGeometry(scrollOffsetCorrection: shift);
        childManager.didFinishLayout();
        return;
      }
      if (!_cacheChanged) break;
    }

    // 5. Position the children and report the geometry.
    var leading = double.infinity;
    var trailing = double.negativeInfinity;
    final reverseCrossAxis =
        axisDirectionIsReversed(constraints.crossAxisDirection);
    final stride = _childCrossAxisExtent + _crossAxisSpacing;
    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      final index = indexOf(child);
      final data = child.parentData! as SliverMasonryGridParentData;
      if (index >= _cache.length) {
        data.layoutOffset = 0;
        continue;
      }
      final entry = _cache[index];
      data.layoutOffset = entry.offset;
      final cross = entry.column * stride;
      data.crossAxisOffset = reverseCrossAxis
          ? constraints.crossAxisExtent - cross - _childCrossAxisExtent
          : cross;
      leading = math.min(leading, entry.offset);
      trailing = math.max(trailing, entry.trailing);
    }
    if (firstChild == null) {
      leading = 0;
      trailing = 0;
    }

    final bool exact = reachedEnd || (hint != null && _cache.length >= hint);
    final double scrollExtent;
    if (exact) {
      scrollExtent = _cache.maxTrailing;
    } else if (hint == null) {
      scrollExtent = double.infinity;
    } else {
      scrollExtent = _cache.estimateTotalExtent(hint);
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

  /// Measures new children until the cache covers [targetEnd]. Returns true
  /// when the last child was found.
  bool _extendCache({
    required double scrollOffset,
    required double targetEnd,
    required int? anchorIndex,
  }) {
    final hint = _childCountHint;
    bool needsMore() {
      if (hint != null && _cache.length >= hint) return false;
      if (_cache.length == 0) return true;
      if (anchorIndex != null && _cache.length <= anchorIndex) return true;
      return _cache.minNextStart < targetEnd;
    }

    if (!needsMore()) return false;

    // Children that end before the target range are not needed any more.
    final firstNeeded = _cache.firstIndexEndingAfter(scrollOffset);
    var foundVisible = firstNeeded != null && anchorIndex == null;
    collectGarbage(
      countChildrenBefore(firstNeeded ?? _cache.length),
      0,
    );

    while (needsMore()) {
      final index = _cache.length;
      if (!foundVisible) {
        // Nothing measured so far is needed: keep at most the last child so
        // that the next one can be attached after it.
        final keep =
            lastChild != null && indexOf(lastChild!) == index - 1 ? 1 : 0;
        collectGarbage(countChildren() - keep, 0);
      }
      final child = obtainChild(index);
      if (child == null) {
        _cache.truncate(index);
        return true;
      }
      final entry = _cache.append(_extentOf(child));
      if (!foundVisible &&
          anchorIndex == null &&
          entry.trailing > scrollOffset) {
        foundVisible = true;
      }
      if (anchorIndex != null && index >= anchorIndex) foundVisible = true;
    }
    return false;
  }

  /// Keeps alive exactly the children between the first child that ends
  /// after [scrollOffset] and the last child that starts before [targetEnd].
  void _materialize(double scrollOffset, double targetEnd) {
    final first = _cache.firstIndexEndingAfter(scrollOffset);
    final last = _cache.lastIndexStartingBefore(targetEnd);
    if (first == null || last == null || last < first) {
      collectGarbage(countChildren(), 0);
      return;
    }
    collectGarbage(countChildrenBefore(first), countChildrenAfter(last));
    for (var index = first; index <= last; index++) {
      obtainChild(index);
    }
  }
}
