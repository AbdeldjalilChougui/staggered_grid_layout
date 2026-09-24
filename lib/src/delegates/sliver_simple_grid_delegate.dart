import 'dart:math' as math;

/// Decides how many tracks (columns for a vertical grid, rows for a
/// horizontal one) a masonry or aligned grid has.
///
/// Unlike [SliverGridDelegate], this delegate does not decide the main axis
/// extent of the children: children size themselves along the main axis.
abstract class SliverSimpleGridDelegate {
  /// Abstract const constructor for subclasses.
  const SliverSimpleGridDelegate();

  /// The number of tracks for a grid whose cross axis is [crossAxisExtent]
  /// long, with [crossAxisSpacing] between tracks. Always at least 1.
  int getCrossAxisCount(double crossAxisExtent, double crossAxisSpacing);

  /// The cross axis extent of one track.
  double getChildCrossAxisExtent(
    double crossAxisExtent,
    double crossAxisSpacing,
  ) {
    final count = getCrossAxisCount(crossAxisExtent, crossAxisSpacing);
    final usable = crossAxisExtent - crossAxisSpacing * (count - 1);
    return math.max(0, usable / count);
  }

  /// Whether a grid using [oldDelegate] must be laid out again when this
  /// delegate replaces it.
  bool shouldRelayout(covariant SliverSimpleGridDelegate oldDelegate);
}

/// A [SliverSimpleGridDelegate] with a fixed number of tracks.
class SliverSimpleGridDelegateWithFixedCrossAxisCount
    extends SliverSimpleGridDelegate {
  /// Creates a delegate with [crossAxisCount] tracks.
  const SliverSimpleGridDelegateWithFixedCrossAxisCount({
    required this.crossAxisCount,
  }) : assert(crossAxisCount > 0);

  /// The number of tracks in the cross axis.
  final int crossAxisCount;

  @override
  int getCrossAxisCount(double crossAxisExtent, double crossAxisSpacing) =>
      math.max(1, crossAxisCount);

  @override
  bool shouldRelayout(SliverSimpleGridDelegateWithFixedCrossAxisCount old) =>
      old.crossAxisCount != crossAxisCount;
}

/// A [SliverSimpleGridDelegate] whose tracks are at most
/// [maxCrossAxisExtent] wide.
///
/// The number of tracks is the smallest number such that each track is no
/// wider than [maxCrossAxisExtent], the same rule as
/// [SliverGridDelegateWithMaxCrossAxisExtent].
class SliverSimpleGridDelegateWithMaxCrossAxisExtent
    extends SliverSimpleGridDelegate {
  /// Creates a delegate whose tracks are at most [maxCrossAxisExtent] wide.
  const SliverSimpleGridDelegateWithMaxCrossAxisExtent({
    required this.maxCrossAxisExtent,
  }) : assert(maxCrossAxisExtent > 0);

  /// The maximum cross axis extent of a track.
  final double maxCrossAxisExtent;

  @override
  int getCrossAxisCount(double crossAxisExtent, double crossAxisSpacing) {
    if (!crossAxisExtent.isFinite || maxCrossAxisExtent <= 0) return 1;
    final count =
        (crossAxisExtent / (maxCrossAxisExtent + crossAxisSpacing)).ceil();
    return math.max(1, count);
  }

  @override
  bool shouldRelayout(SliverSimpleGridDelegateWithMaxCrossAxisExtent old) =>
      old.maxCrossAxisExtent != maxCrossAxisExtent;
}
