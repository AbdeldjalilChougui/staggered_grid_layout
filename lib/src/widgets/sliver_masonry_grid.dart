import 'package:flutter/widgets.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import '../rendering/sliver_masonry_grid.dart';

/// A lazy sliver that places children Pinterest-style.
///
/// Every child goes into the column whose content currently ends first; when
/// several columns end at the same offset the lowest column index wins, so
/// the layout is deterministic. Children size themselves along the main axis
/// and are built only when they are visible or inside the cache extent.
///
/// Placements are cached by index. Scrolling back up reuses the exact
/// positions computed on the way down, so the grid never re-guesses a layout
/// while scrolling. When a child changes size it keeps its column:
///
/// * a child that starts inside the viewport (or below it) grows at its
///   trailing edge and pushes the later children of its column;
/// * a child that starts above the viewport grows at its leading edge, so
///   content on screen does not move.
///
/// Use it inside a [CustomScrollView], or use [MasonryGridView].
class SliverMasonryGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates a masonry sliver from a [SliverChildDelegate].
  const SliverMasonryGrid({
    super.key,
    required super.delegate,
    required this.gridDelegate,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0);

  /// Creates a masonry sliver with [crossAxisCount] columns whose children
  /// are built lazily by [itemBuilder].
  ///
  /// When [childCount] is null the grid grows until [itemBuilder] returns
  /// null.
  SliverMasonryGrid.count({
    super.key,
    required int crossAxisCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? childCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  })  : gridDelegate = SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        ),
        super(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: childCount,
            findChildIndexCallback: findChildIndexCallback,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
        );

  /// Creates a masonry sliver whose columns are at most [maxCrossAxisExtent]
  /// wide, with children built lazily by [itemBuilder].
  SliverMasonryGrid.extent({
    super.key,
    required double maxCrossAxisExtent,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? childCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  })  : gridDelegate = SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
        ),
        super(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: childCount,
            findChildIndexCallback: findChildIndexCallback,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
        );

  /// Decides the number of columns.
  final SliverSimpleGridDelegate gridDelegate;

  /// The space between two children of the same column.
  final double mainAxisSpacing;

  /// The space between two columns.
  final double crossAxisSpacing;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverMasonryGrid createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverMasonryGrid(
      childManager: element,
      gridDelegate: gridDelegate,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childCountHint: delegate.estimatedChildCount,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverMasonryGrid renderObject,
  ) {
    renderObject
      ..gridDelegate = gridDelegate
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..childCountHint = delegate.estimatedChildCount;
  }
}
