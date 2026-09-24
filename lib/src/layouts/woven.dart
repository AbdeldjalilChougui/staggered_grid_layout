import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'pattern_grid_layout.dart';

/// A tile of a woven pattern.
@immutable
class WovenGridTile {
  /// Creates a tile whose cross axis extent divided by its main axis extent
  /// is [aspectRatio].
  const WovenGridTile(
    this.aspectRatio, {
    this.crossAxisRatio = 1,
    this.alignment = AlignmentDirectional.center,
  })  : assert(aspectRatio > 0),
        assert(crossAxisRatio > 0 && crossAxisRatio <= 1);

  /// Cross axis extent divided by main axis extent.
  final double aspectRatio;

  /// Fraction of the track width the tile takes, in (0, 1].
  final double crossAxisRatio;

  /// Where the tile sits inside its cell.
  ///
  /// The first track of each block resolves it with the ambient reading
  /// direction and the second track with the opposite one, which gives the
  /// woven look.
  final AlignmentDirectional alignment;

  @override
  bool operator ==(Object other) =>
      other is WovenGridTile &&
      other.aspectRatio == aspectRatio &&
      other.crossAxisRatio == crossAxisRatio &&
      other.alignment == alignment;

  @override
  int get hashCode => Object.hash(aspectRatio, crossAxisRatio, alignment);
}

/// A [SliverGridDelegate] that lays children out in blocks of two tracks,
/// the second track using the [pattern] in reverse order.
///
/// With a two-tile pattern `A B` and three columns the blocks read
/// `A B A` / `B A B`. Every cell of a track is as long as the longest tile of
/// the pattern, and each tile is aligned inside its cell with its
/// [WovenGridTile.alignment].
class SliverWovenGridDelegate extends SliverGridDelegate {
  /// Creates a woven delegate with [crossAxisCount] columns.
  SliverWovenGridDelegate.count({
    required List<WovenGridTile> pattern,
    required int this.crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.tileBottomSpace = 0,
  })  : assert(crossAxisCount > 0),
        assert(pattern.isNotEmpty),
        maxCrossAxisExtent = null,
        pattern = List<WovenGridTile>.unmodifiable(pattern);

  /// Creates a woven delegate whose columns are at most [maxCrossAxisExtent]
  /// wide.
  SliverWovenGridDelegate.extent({
    required List<WovenGridTile> pattern,
    required double this.maxCrossAxisExtent,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.tileBottomSpace = 0,
  })  : assert(maxCrossAxisExtent > 0),
        assert(pattern.isNotEmpty),
        crossAxisCount = null,
        pattern = List<WovenGridTile>.unmodifiable(pattern);

  /// The tiles of the pattern.
  final List<WovenGridTile> pattern;

  /// Fixed number of columns, or null when [maxCrossAxisExtent] is used.
  final int? crossAxisCount;

  /// Maximum column width, or null when [crossAxisCount] is used.
  final double? maxCrossAxisExtent;

  /// Space between tracks.
  final double mainAxisSpacing;

  /// Space between columns.
  final double crossAxisSpacing;

  /// Extra main axis space added after each tile, for a caption for
  /// instance.
  final double tileBottomSpace;

  int _columns(double crossAxisExtent) {
    final fixed = crossAxisCount;
    if (fixed != null) return math.max(1, fixed);
    final count =
        (crossAxisExtent / (maxCrossAxisExtent! + crossAxisSpacing)).ceil();
    return math.max(1, count);
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final columns = _columns(crossAxisExtent);
    final cell = math.max(
      0.0,
      (crossAxisExtent - crossAxisSpacing * (columns - 1)) / columns,
    );
    final vertical = constraints.axis == Axis.vertical;
    var ratio = 0.0;
    for (final tile in pattern) {
      ratio = math.max(ratio, tile.crossAxisRatio / tile.aspectRatio);
    }
    final track = cell * ratio + tileBottomSpace;
    final tiles = <PatternTile>[];
    for (var i = 0; i < columns * 2; i++) {
      final second = i >= columns;
      final column = i % columns;
      final tile = pattern[second
          ? (columns * 2 - 1 - column) % pattern.length
          : i % pattern.length];
      final tileCross = cell * tile.crossAxisRatio;
      final tileMain = tileCross / tile.aspectRatio + tileBottomSpace;
      final alignment = tile.alignment
          .resolve(second ? TextDirection.rtl : TextDirection.ltr);
      final alongCross = vertical ? alignment.x : alignment.y;
      final alongMain = vertical ? alignment.y : alignment.x;
      tiles.add(PatternTile(
        mainAxisOffset: (second ? track + mainAxisSpacing : 0) +
            (track - tileMain) * (alongMain + 1) / 2,
        mainAxisExtent: tileMain,
        crossAxisOffset: column * (cell + crossAxisSpacing) +
            (cell - tileCross) * (alongCross + 1) / 2,
        crossAxisExtent: tileCross,
      ));
    }
    return PatternGridLayout(
      tiles: tiles,
      blockStride: math.max(2 * (track + mainAxisSpacing), 1e-10),
      crossAxisExtent: crossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverWovenGridDelegate oldDelegate) =>
      oldDelegate.crossAxisCount != crossAxisCount ||
      oldDelegate.maxCrossAxisExtent != maxCrossAxisExtent ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      oldDelegate.tileBottomSpace != tileBottomSpace ||
      !listEquals(oldDelegate.pattern, pattern);
}
