import 'package:flutter/widgets.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import 'sliver_aligned_grid.dart';

/// A scrollable grid whose rows are as tall as their tallest child: a
/// [BoxScrollView] around a [SliverAlignedGrid].
class AlignedGridView extends BoxScrollView {
  /// Creates an aligned grid whose children are built lazily by
  /// [itemBuilder].
  ///
  /// When [itemCount] is null the grid grows until [itemBuilder] returns
  /// null, or forever.
  const AlignedGridView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.gridDelegate,
    required this.itemBuilder,
    this.itemCount,
    this.findChildIndexCallback,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  });

  /// Creates an aligned grid with [crossAxisCount] children per row.
  AlignedGridView.count({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required int crossAxisCount,
    required this.itemBuilder,
    this.itemCount,
    this.findChildIndexCallback,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : gridDelegate = SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        );

  /// Creates an aligned grid whose children are at most
  /// [maxCrossAxisExtent] wide.
  AlignedGridView.extent({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required double maxCrossAxisExtent,
    required this.itemBuilder,
    this.itemCount,
    this.findChildIndexCallback,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
  }) : gridDelegate = SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
        );

  /// Decides the number of children per row.
  final SliverSimpleGridDelegate gridDelegate;

  /// Builds the child at an index, or returns null past the end.
  final NullableIndexedWidgetBuilder itemBuilder;

  /// The number of children, or null to build until [itemBuilder] returns
  /// null.
  final int? itemCount;

  /// Finds the new index of a keyed child after the data changed.
  final ChildIndexGetter? findChildIndexCallback;

  /// The space between two rows.
  final double mainAxisSpacing;

  /// The space between two children of a row.
  final double crossAxisSpacing;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics].
  final bool addSemanticIndexes;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SliverAlignedGrid(
      gridDelegate: gridDelegate,
      itemBuilder: itemBuilder,
      itemCount: itemCount,
      findChildIndexCallback: findChildIndexCallback,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
    );
  }
}
