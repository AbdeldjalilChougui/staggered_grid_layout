import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// One tile of a repeating block, in block coordinates.
///
/// Cross axis offsets are measured from the start of the cross axis in
/// left-to-right (or top-to-bottom) order; [PatternGridLayout] mirrors them
/// when the cross axis is reversed.
@immutable
class PatternTile {
  /// Creates a tile.
  const PatternTile({
    required this.mainAxisOffset,
    required this.mainAxisExtent,
    required this.crossAxisOffset,
    required this.crossAxisExtent,
  });

  /// Offset of the leading edge along the main axis, inside the block.
  final double mainAxisOffset;

  /// Extent along the main axis.
  final double mainAxisExtent;

  /// Offset along the cross axis.
  final double crossAxisOffset;

  /// Extent along the cross axis.
  final double crossAxisExtent;

  /// Offset of the trailing edge along the main axis, inside the block.
  double get mainAxisTrailing => mainAxisOffset + mainAxisExtent;
}

/// A [SliverGridLayout] that repeats a block of tiles along the main axis.
///
/// Child `i` uses tile `i % tiles.length` of block `i ~/ tiles.length`, and
/// block `b` starts at `b * blockStride`. Tiles do not need to be sorted:
/// the index queries used by [RenderSliverGrid] scan the whole block, so a
/// tile placed above an earlier tile is still found.
class PatternGridLayout extends SliverGridLayout {
  /// Creates a layout.
  PatternGridLayout({
    required this.tiles,
    required this.blockStride,
    required this.crossAxisExtent,
    required this.reverseCrossAxis,
  })  : assert(tiles.isNotEmpty),
        assert(blockStride > 0);

  /// The tiles of one block.
  final List<PatternTile> tiles;

  /// Distance between the starts of two consecutive blocks.
  final double blockStride;

  /// The cross axis extent of the sliver.
  final double crossAxisExtent;

  /// Whether cross axis offsets must be mirrored (RTL, for instance).
  final bool reverseCrossAxis;

  int get _count => tiles.length;

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (!scrollOffset.isFinite || scrollOffset <= 0) return 0;
    final block = (scrollOffset / blockStride).floor();
    final local = scrollOffset - block * blockStride;
    for (var i = 0; i < _count; i++) {
      if (tiles[i].mainAxisTrailing > local) return block * _count + i;
    }
    return (block + 1) * _count;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    if (!scrollOffset.isFinite) return 1 << 30;
    final block = math.max(0, (scrollOffset / blockStride).floor());
    final local = scrollOffset - block * blockStride;
    var result = block * _count - 1;
    for (var i = _count - 1; i >= 0; i--) {
      if (tiles[i].mainAxisOffset < local) {
        result = block * _count + i;
        break;
      }
    }
    // RenderSliverGrid always lays out at least the first child.
    return math.max(result, 0);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final tile = tiles[index % _count];
    final block = index ~/ _count;
    final cross = reverseCrossAxis
        ? crossAxisExtent - tile.crossAxisOffset - tile.crossAxisExtent
        : tile.crossAxisOffset;
    return SliverGridGeometry(
      scrollOffset: block * blockStride + tile.mainAxisOffset,
      crossAxisOffset: cross,
      mainAxisExtent: tile.mainAxisExtent,
      crossAxisExtent: tile.crossAxisExtent,
    );
  }

  @override
  double computeMaxScrollOffset(int childCount) {
    if (childCount <= 0) return 0;
    final fullBlocks = (childCount - 1) ~/ _count;
    final lastTile = (childCount - 1) % _count;
    var trailing = 0.0;
    for (var i = 0; i <= lastTile; i++) {
      trailing = math.max(trailing, tiles[i].mainAxisTrailing);
    }
    return fullBlocks * blockStride + trailing;
  }
}
