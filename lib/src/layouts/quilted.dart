import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'pattern_grid_layout.dart';

/// A tile of a quilted pattern, measured in grid cells.
@immutable
class QuiltedGridTile {
  /// Creates a tile spanning [mainAxisCount] cells along the main axis and
  /// [crossAxisCount] cells along the cross axis.
  const QuiltedGridTile(this.mainAxisCount, this.crossAxisCount)
      : assert(mainAxisCount > 0),
        assert(crossAxisCount > 0);

  /// Number of cells along the main axis.
  final int mainAxisCount;

  /// Number of cells along the cross axis.
  final int crossAxisCount;

  @override
  bool operator ==(Object other) =>
      other is QuiltedGridTile &&
      other.mainAxisCount == mainAxisCount &&
      other.crossAxisCount == crossAxisCount;

  @override
  int get hashCode => Object.hash(mainAxisCount, crossAxisCount);

  @override
  String toString() => 'QuiltedGridTile($mainAxisCount, $crossAxisCount)';
}

/// How a quilted pattern repeats along the main axis.
enum QuiltedGridRepeatPattern {
  /// Every block is identical.
  same,

  /// Every second block is rotated by 180 degrees (central inversion).
  inverted,

  /// Every second block is mirrored along the cross axis.
  mirrored,
}

/// Cell coordinates of a placed quilted tile.
typedef _Cell = ({int row, int column, QuiltedGridTile tile});

/// A [SliverGridDelegate] that lays children out in square cells following a
/// repeating [pattern] of [QuiltedGridTile]s.
///
/// Tiles are placed in pattern order, each in the first free position
/// (scanning rows, then columns) where it fits. The block of the pattern is
/// as tall as its lowest tile and repeats along the main axis according to
/// [repeatPattern]. Positions that no tile covers stay empty, so a pattern
/// meant to repeat seamlessly should fill a full rectangle.
///
/// Use it with [SliverQuiltedGrid], [SliverGrid] or [GridView.custom].
class SliverQuiltedGridDelegate extends SliverGridDelegate {
  /// Creates a quilted grid delegate.
  SliverQuiltedGridDelegate({
    required this.crossAxisCount,
    required List<QuiltedGridTile> pattern,
    this.repeatPattern = QuiltedGridRepeatPattern.same,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  })  : assert(crossAxisCount > 0),
        assert(pattern.isNotEmpty),
        assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        assert(
          pattern.every((t) => t.crossAxisCount <= crossAxisCount),
          'A tile of the pattern is wider than crossAxisCount.',
        ),
        pattern = List<QuiltedGridTile>.unmodifiable(pattern);

  /// Number of cells along the cross axis.
  final int crossAxisCount;

  /// The tiles of one block, in child order.
  final List<QuiltedGridTile> pattern;

  /// How the pattern repeats.
  final QuiltedGridRepeatPattern repeatPattern;

  /// Space between cells along the main axis.
  final double mainAxisSpacing;

  /// Space between cells along the cross axis.
  final double crossAxisSpacing;

  /// Places the pattern in cell coordinates. Returns the placed tiles in
  /// child order and the block height in cells.
  (List<_Cell>, int) _place() {
    final occupied = <List<bool>>[];
    bool free(int row, int column) =>
        row >= occupied.length || !occupied[row][column];
    final cells = <_Cell>[];
    var rows = 0;
    for (final pattern in this.pattern) {
      final tile = QuiltedGridTile(
        pattern.mainAxisCount,
        math.min(pattern.crossAxisCount, crossAxisCount),
      );
      var placed = false;
      for (var row = 0; !placed; row++) {
        for (var column = 0;
            column + tile.crossAxisCount <= crossAxisCount;
            column++) {
          var fits = true;
          for (var r = row; fits && r < row + tile.mainAxisCount; r++) {
            for (var c = column; c < column + tile.crossAxisCount; c++) {
              if (!free(r, c)) {
                fits = false;
                break;
              }
            }
          }
          if (!fits) continue;
          while (occupied.length < row + tile.mainAxisCount) {
            occupied.add(List<bool>.filled(crossAxisCount, false));
          }
          for (var r = row; r < row + tile.mainAxisCount; r++) {
            for (var c = column; c < column + tile.crossAxisCount; c++) {
              occupied[r][c] = true;
            }
          }
          cells.add((row: row, column: column, tile: tile));
          rows = math.max(rows, row + tile.mainAxisCount);
          placed = true;
          break;
        }
      }
    }
    return (cells, rows);
  }

  List<_Cell> _transformed(List<_Cell> cells, int rows) {
    final result = [
      for (final cell in cells)
        (
          row: repeatPattern == QuiltedGridRepeatPattern.inverted
              ? rows - cell.row - cell.tile.mainAxisCount
              : cell.row,
          column: crossAxisCount - cell.column - cell.tile.crossAxisCount,
          tile: cell.tile,
        ),
    ];
    // Children of the repeated block follow reading order.
    result.sort((a, b) =>
        a.row != b.row ? a.row.compareTo(b.row) : a.column.compareTo(b.column));
    return result;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final crossAxisExtent = constraints.crossAxisExtent;
    final cellExtent = math.max(
      0.0,
      (crossAxisExtent - crossAxisSpacing * (crossAxisCount - 1)) /
          crossAxisCount,
    );
    final mainStride = cellExtent + mainAxisSpacing;
    final crossStride = cellExtent + crossAxisSpacing;
    final (cells, rows) = _place();

    PatternTile toTile(_Cell cell, int rowOffset) => PatternTile(
          mainAxisOffset: (cell.row + rowOffset) * mainStride,
          mainAxisExtent: cell.tile.mainAxisCount * cellExtent +
              (cell.tile.mainAxisCount - 1) * mainAxisSpacing,
          crossAxisOffset: cell.column * crossStride,
          crossAxisExtent: cell.tile.crossAxisCount * cellExtent +
              (cell.tile.crossAxisCount - 1) * crossAxisSpacing,
        );

    final tiles = [for (final cell in cells) toTile(cell, 0)];
    var blocks = 1;
    if (repeatPattern != QuiltedGridRepeatPattern.same) {
      tiles.addAll([
        for (final cell in _transformed(cells, rows)) toTile(cell, rows),
      ]);
      blocks = 2;
    }
    return PatternGridLayout(
      tiles: tiles,
      blockStride: math.max(blocks * rows * mainStride, 1e-10),
      crossAxisExtent: crossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverQuiltedGridDelegate oldDelegate) =>
      oldDelegate.crossAxisCount != crossAxisCount ||
      oldDelegate.repeatPattern != repeatPattern ||
      oldDelegate.mainAxisSpacing != mainAxisSpacing ||
      oldDelegate.crossAxisSpacing != crossAxisSpacing ||
      !listEquals(oldDelegate.pattern, pattern);
}
