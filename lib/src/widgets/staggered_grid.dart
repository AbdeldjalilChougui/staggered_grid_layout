import 'package:flutter/widgets.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import '../rendering/staggered_grid.dart';

/// A non-scrolling grid of tiles that span several columns and rows.
///
/// Wrap children in [StaggeredGridTile] to choose their size; plain children
/// span one column and size themselves along the main axis. Each tile goes
/// into the group of columns whose content ends first (ties go to the lowest
/// column), so the order of [children] is the reading order.
///
/// Because every child is built and laid out, use it for small grids or
/// inside a scroll view, not for long lists: use [SliverMasonryGrid] or
/// [SliverQuiltedGrid] for those.
class StaggeredGrid extends MultiChildRenderObjectWidget {
  /// Creates a grid with [crossAxisCount] columns.
  StaggeredGrid.count({
    super.key,
    required int crossAxisCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.axisDirection,
    super.children,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        delegate = SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
        );

  /// Creates a grid whose columns are at most [maxCrossAxisExtent] wide.
  StaggeredGrid.extent({
    super.key,
    required double maxCrossAxisExtent,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    this.axisDirection,
    super.children,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        delegate = SliverSimpleGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: maxCrossAxisExtent,
        );

  /// Decides the number of columns.
  final SliverSimpleGridDelegate delegate;

  /// Space between tiles along the main axis.
  final double mainAxisSpacing;

  /// Space between columns.
  final double crossAxisSpacing;

  /// The direction in which the main axis grows.
  ///
  /// When null, the grid grows down, or right when it sits in a horizontal
  /// [Scrollable].
  final AxisDirection? axisDirection;

  AxisDirection _axisDirection(BuildContext context) {
    final explicit = axisDirection;
    if (explicit != null) return explicit;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null &&
        axisDirectionToAxis(scrollable.axisDirection) == Axis.horizontal) {
      return AxisDirection.right;
    }
    return AxisDirection.down;
  }

  @override
  RenderStaggeredGrid createRenderObject(BuildContext context) {
    return RenderStaggeredGrid(
      delegate: delegate,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      axisDirection: _axisDirection(context),
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStaggeredGrid renderObject,
  ) {
    renderObject
      ..delegate = delegate
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..axisDirection = _axisDirection(context)
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

/// Sets the size of a child of a [StaggeredGrid].
class StaggeredGridTile extends ParentDataWidget<StaggeredGridParentData> {
  const StaggeredGridTile._({
    super.key,
    required this.crossAxisCellCount,
    required this.mainAxisCellCount,
    required this.mainAxisExtent,
    required super.child,
  }) : assert(crossAxisCellCount > 0);

  /// A tile spanning [crossAxisCellCount] columns and [mainAxisCellCount]
  /// cells along the main axis. Cells are as long as they are wide, and
  /// [mainAxisCellCount] may be fractional.
  const StaggeredGridTile.count({
    Key? key,
    required int crossAxisCellCount,
    required num mainAxisCellCount,
    required Widget child,
  }) : this._(
          key: key,
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          mainAxisExtent: null,
          child: child,
        );

  /// A tile spanning [crossAxisCellCount] columns with a fixed
  /// [mainAxisExtent].
  const StaggeredGridTile.extent({
    Key? key,
    required int crossAxisCellCount,
    required double mainAxisExtent,
    required Widget child,
  }) : this._(
          key: key,
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: null,
          mainAxisExtent: mainAxisExtent,
          child: child,
        );

  /// A tile spanning [crossAxisCellCount] columns whose main axis extent is
  /// the extent of its child.
  const StaggeredGridTile.fit({
    Key? key,
    required int crossAxisCellCount,
    required Widget child,
  }) : this._(
          key: key,
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: null,
          mainAxisExtent: null,
          child: child,
        );

  /// Number of columns the tile spans.
  final int crossAxisCellCount;

  /// Number of cells along the main axis, or null.
  final num? mainAxisCellCount;

  /// Fixed main axis extent, or null.
  final double? mainAxisExtent;

  @override
  void applyParentData(RenderObject renderObject) {
    final data = renderObject.parentData! as StaggeredGridParentData;
    if (data.crossAxisCellCount != crossAxisCellCount ||
        data.mainAxisCellCount != mainAxisCellCount ||
        data.mainAxisExtent != mainAxisExtent) {
      data
        ..crossAxisCellCount = crossAxisCellCount
        ..mainAxisCellCount = mainAxisCellCount
        ..mainAxisExtent = mainAxisExtent;
      renderObject.parent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => StaggeredGrid;
}
