import 'package:flutter/widgets.dart';

import '../layouts/quilted.dart';
import '../layouts/woven.dart';

/// A lazy [SliverGrid] that follows a repeating quilted pattern.
///
/// See [SliverQuiltedGridDelegate] for the placement rules.
class SliverQuiltedGrid extends SliverGrid {
  /// Creates a quilted grid from a [SliverChildDelegate].
  SliverQuiltedGrid({
    super.key,
    required super.delegate,
    required int crossAxisCount,
    required List<QuiltedGridTile> pattern,
    QuiltedGridRepeatPattern repeatPattern = QuiltedGridRepeatPattern.same,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
  }) : super(
          gridDelegate: SliverQuiltedGridDelegate(
            crossAxisCount: crossAxisCount,
            pattern: pattern,
            repeatPattern: repeatPattern,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
          ),
        );

  /// Creates a quilted grid whose children are built lazily by
  /// [itemBuilder].
  SliverQuiltedGrid.builder({
    super.key,
    required int crossAxisCount,
    required List<QuiltedGridTile> pattern,
    required NullableIndexedWidgetBuilder itemBuilder,
    int? itemCount,
    QuiltedGridRepeatPattern repeatPattern = QuiltedGridRepeatPattern.same,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
  }) : super(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
            findChildIndexCallback: findChildIndexCallback,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          ),
          gridDelegate: SliverQuiltedGridDelegate(
            crossAxisCount: crossAxisCount,
            pattern: pattern,
            repeatPattern: repeatPattern,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
          ),
        );
}

/// A lazy [SliverGrid] that weaves a pattern of tiles across pairs of
/// tracks.
///
/// See [SliverWovenGridDelegate] for the placement rules.
class SliverWovenGrid extends SliverGrid {
  /// Creates a woven grid with [crossAxisCount] columns.
  SliverWovenGrid.count({
    super.key,
    required super.delegate,
    required int crossAxisCount,
    required List<WovenGridTile> pattern,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double tileBottomSpace = 0,
  }) : super(
          gridDelegate: SliverWovenGridDelegate.count(
            crossAxisCount: crossAxisCount,
            pattern: pattern,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            tileBottomSpace: tileBottomSpace,
          ),
        );

  /// Creates a woven grid whose columns are at most [maxCrossAxisExtent]
  /// wide.
  SliverWovenGrid.extent({
    super.key,
    required super.delegate,
    required double maxCrossAxisExtent,
    required List<WovenGridTile> pattern,
    double mainAxisSpacing = 0,
    double crossAxisSpacing = 0,
    double tileBottomSpace = 0,
  }) : super(
          gridDelegate: SliverWovenGridDelegate.extent(
            maxCrossAxisExtent: maxCrossAxisExtent,
            pattern: pattern,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            tileBottomSpace: tileBottomSpace,
          ),
        );
}
