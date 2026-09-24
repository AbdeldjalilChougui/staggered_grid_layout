import 'package:flutter/widgets.dart';

import '../delegates/sliver_simple_grid_delegate.dart';
import '../rendering/sliver_aligned_grid.dart';

/// A lazy sliver that lays children out in rows, each row as tall as its
/// tallest child. Every child of a row is stretched to the row extent.
///
/// Children are built only when their row is visible or inside the cache
/// extent. Rows are measured once and cached, so scrolling back up does not
/// re-guess the layout.
class SliverAlignedGrid extends SliverMultiBoxAdaptorWidget {
  /// Creates an aligned grid sliver.
  ///
  /// When [itemCount] is null the grid grows until [itemBuilder] returns
  /// null, or forever.
  SliverAlignedGrid({
    super.key,
    required this.gridDelegate,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    this.mainAxisSpacing = 0,
    this.crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  })  : assert(mainAxisSpacing >= 0),
        assert(crossAxisSpacing >= 0),
        super(
          delegate: _cellDelegate(
            itemBuilder,
            itemCount,
            findChildIndexCallback,
            addAutomaticKeepAlives,
            addRepaintBoundaries,
            addSemanticIndexes,
          ),
        );

  /// Creates an aligned grid sliver with [crossAxisCount] children per row.
  SliverAlignedGrid.count({
    Key? key,
    required int crossAxisCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : this(
          key: key,
          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          findChildIndexCallback: findChildIndexCallback,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Creates an aligned grid sliver whose children are at most
  /// [maxCrossAxisExtent] wide.
  SliverAlignedGrid.extent({
    Key? key,
    required double maxCrossAxisExtent,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : this(
          key: key,
          gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCrossAxisExtent,
          ),
          itemBuilder: itemBuilder,
          itemCount: itemCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          findChildIndexCallback: findChildIndexCallback,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );

  /// Decides the number of children per row.
  final SliverSimpleGridDelegate gridDelegate;

  /// The space between two rows.
  final double mainAxisSpacing;

  /// The space between two children of a row.
  final double crossAxisSpacing;

  static SliverChildDelegate _cellDelegate(
    NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives,
    bool addRepaintBoundaries,
    bool addSemanticIndexes,
  ) {
    return SliverChildBuilderDelegate(
      (context, index) {
        final item = itemBuilder(context, index);
        if (item == null) return null;
        final key = item.key;
        return _AlignedGridCell(
          key: key == null ? null : _CellKey(key),
          child: item,
        );
      },
      childCount: itemCount,
      findChildIndexCallback: findChildIndexCallback == null
          ? null
          : (key) => key is _CellKey ? findChildIndexCallback(key.key) : null,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
    );
  }

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverAlignedGrid createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverAlignedGrid(
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
    RenderSliverAlignedGrid renderObject,
  ) {
    renderObject
      ..gridDelegate = gridDelegate
      ..mainAxisSpacing = mainAxisSpacing
      ..crossAxisSpacing = crossAxisSpacing
      ..childCountHint = delegate.estimatedChildCount;
  }
}

/// Wraps the key of an item so that the cell and the item can both keep a
/// key without clashing.
class _CellKey extends LocalKey {
  const _CellKey(this.key);

  final Key key;

  @override
  bool operator ==(Object other) => other is _CellKey && other.key == key;

  @override
  int get hashCode => Object.hash(_CellKey, key);
}

class _AlignedGridCell extends SingleChildRenderObjectWidget {
  const _AlignedGridCell({super.key, required super.child});

  @override
  RenderAlignedGridCell createRenderObject(BuildContext context) =>
      RenderAlignedGridCell();
}
