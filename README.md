# staggered_grid_layout

Masonry, quilted, woven, aligned and staggered grids for Flutter, built on
real slivers. Layouts are cached by index, so scrolling back up does not
jump, and every layout supports RTL and both scroll axes.

[![pub package](https://img.shields.io/pub/v/staggered_grid_layout.svg)](https://pub.dev/packages/staggered_grid_layout)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Features

| Layout | Widgets | Children |
|---|---|---|
| Masonry (Pinterest) | `SliverMasonryGrid` (`.count`, `.extent`), `MasonryGridView` (`.count`, `.extent`, `.builder`, `.custom`) | Built lazily, size themselves along the main axis |
| Aligned rows | `SliverAlignedGrid` (`.count`, `.extent`), `AlignedGridView` (`.count`, `.extent`, `.builder`) | Built lazily, stretched to the tallest child of their row |
| Quilted | `SliverQuiltedGrid` (`.builder`), `SliverQuiltedGridDelegate` | Built lazily by Flutter's `SliverGrid`, sized by the pattern |
| Woven | `SliverWovenGrid` (`.count`, `.extent`), `SliverWovenGridDelegate` | Built lazily by Flutter's `SliverGrid`, sized by the pattern |
| Staggered | `StaggeredGrid` (`.count`, `.extent`) with `StaggeredGridTile.count`, `.extent` and `.fit` | Non-scrolling, all built |

- **Real slivers.** Masonry and aligned grids are `RenderSliverMultiBoxAdaptor`
  slivers. They build only the children that are visible or inside the cache
  extent, dispose the others, report an exact `SliverGeometry` once every
  child has been measured, and support keep-alive. Quilted and woven grids
  are `SliverGridDelegate`s for Flutter's own `RenderSliverGrid`.
- **No jumps when scrolling up.** Each masonry placement (column, offset,
  extent) is cached by index, so scrolling back up reuses the layout computed
  on the way down. When a child changes size it keeps its column. A child
  that starts above the viewport grows upward and the scroll offset is
  corrected, so what is on screen stays put. Aligned grids cache row extents
  the same way.
- **Deterministic placement.** A child goes into the column whose content
  ends first. Ties go to the lowest column, even with floating-point noise.
- **Crash-free data changes.** Insert, remove and reorder, with or without
  `findChildIndexCallback`, and change the column count while scrolled; the
  first visible child stays on screen.
- **GridView parity.** `mainAxisSpacing`, `crossAxisSpacing`, padding,
  `addAutomaticKeepAlives`, `addRepaintBoundaries`, `addSemanticIndexes`,
  `cacheExtent`, `reverse`, `shrinkWrap`, `controller` and `physics`.
- **RTL and both axes.** Columns mirror under `TextDirection.rtl`; every
  layout scrolls vertically or horizontally.
- **No dependencies** besides Flutter.

## Install

```yaml
dependencies:
  staggered_grid_layout: ^0.1.0
```

```dart
import 'package:staggered_grid_layout/staggered_grid_layout.dart';
```

## Usage

### Masonry

```dart
MasonryGridView.count(
  crossAxisCount: 3,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  padding: const EdgeInsets.all(8),
  itemCount: photos.length,
  itemBuilder: (context, index) => PhotoCard(photos[index]),
)
```

Inside a `CustomScrollView`:

```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(title: Text('Feed')),
    SliverMasonryGrid.extent(
      maxCrossAxisExtent: 200,
      childCount: posts.length,
      itemBuilder: (context, index) => PostCard(posts[index]),
    ),
  ],
)
```

Leave `itemCount` (or `childCount`) null for an endless feed. The grid grows
until `itemBuilder` returns null.

### Aligned rows

```dart
AlignedGridView.count(
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  itemCount: products.length,
  itemBuilder: (context, index) => ProductCard(products[index]),
)
```

### Quilted

```dart
CustomScrollView(
  slivers: [
    SliverQuiltedGrid.builder(
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      repeatPattern: QuiltedGridRepeatPattern.mirrored,
      pattern: const [
        QuiltedGridTile(2, 2), // mainAxisCount, crossAxisCount
        QuiltedGridTile(1, 1),
        QuiltedGridTile(1, 1),
        QuiltedGridTile(1, 2),
      ],
      itemCount: images.length,
      itemBuilder: (context, index) => ImageTile(images[index]),
    ),
  ],
)
```

The delegate also works with `GridView.custom` and `SliverGrid`:

```dart
GridView.custom(
  gridDelegate: SliverQuiltedGridDelegate(
    crossAxisCount: 4,
    pattern: const [QuiltedGridTile(2, 2), QuiltedGridTile(1, 2)],
  ),
  childrenDelegate: SliverChildBuilderDelegate(
    (context, index) => ImageTile(images[index]),
    childCount: images.length,
  ),
)
```

### Woven

```dart
SliverWovenGrid.count(
  crossAxisCount: 2,
  mainAxisSpacing: 8,
  crossAxisSpacing: 8,
  pattern: const [
    WovenGridTile(1),
    WovenGridTile(
      5 / 7,
      crossAxisRatio: 0.9,
      alignment: AlignmentDirectional.centerEnd,
    ),
  ],
  delegate: SliverChildBuilderDelegate(
    (context, index) => ImageTile(images[index]),
    childCount: images.length,
  ),
)
```

### Staggered

```dart
StaggeredGrid.count(
  crossAxisCount: 4,
  mainAxisSpacing: 4,
  crossAxisSpacing: 4,
  children: const [
    StaggeredGridTile.count(
      crossAxisCellCount: 2,
      mainAxisCellCount: 2,
      child: Tile(0),
    ),
    StaggeredGridTile.extent(
      crossAxisCellCount: 2,
      mainAxisExtent: 120,
      child: Tile(1),
    ),
    StaggeredGridTile.fit(crossAxisCellCount: 2, child: Tile(2)),
  ],
)
```

The `example/` app demos every layout and has an RTL switch.

## Migrating from flutter_staggered_grid_view

Most code migrates by changing the import. Class and constructor names are
the same unless the table says otherwise.

| flutter_staggered_grid_view 0.7.0 | staggered_grid_layout | Notes |
|---|---|---|
| `import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart'` | `import 'package:staggered_grid_layout/staggered_grid_layout.dart'` | |
| `MasonryGridView`, `.count`, `.extent`, `.builder`, `.custom` | same | `itemBuilder` may return null; adds `findChildIndexCallback` |
| `SliverMasonryGrid`, `.count`, `.extent` | same | adds `findChildIndexCallback`, `addAutomaticKeepAlives`, `addRepaintBoundaries`, `addSemanticIndexes` |
| `AlignedGridView.count`, `.extent` | same | adds `findChildIndexCallback` |
| `AlignedGridView.custom(gridDelegate:, itemBuilder:)` | `AlignedGridView.builder(gridDelegate:, itemBuilder:)` | renamed, since it takes a builder |
| `SliverAlignedGrid`, `.count`, `.extent` | same | |
| `SliverSimpleGridDelegateWithFixedCrossAxisCount` | same | |
| `SliverSimpleGridDelegateWithMaxCrossAxisExtent` | same | |
| subclass of `SliverSimpleGridDelegate` | same base class | override `getCrossAxisCount(double crossAxisExtent, double crossAxisSpacing)` and `shouldRelayout` |
| `StaggeredGrid.count`, `.extent` | same | `axisDirection` defaults to the axis of the enclosing `Scrollable` |
| `StaggeredGrid.custom` | not provided | use `.count` or `.extent` |
| `StaggeredGridTile.count`, `.extent`, `.fit` | same | |
| `QuiltedGridTile(mainAxisCount, crossAxisCount)` | same | |
| `QuiltedGridRepeatPattern.same`, `.inverted`, `.mirrored` | same, now an enum | custom repeat patterns are not supported |
| `SliverQuiltedGridDelegate` | same | also available as the `SliverQuiltedGrid` sliver |
| `WovenGridTile`, `SliverWovenGridDelegate.count`, `.extent` | same | also available as `SliverWovenGrid.count` and `.extent`; `tileBottomSpace` always runs along the main axis |
| `StairedGridTile`, `SliverStairedGridDelegate` | not provided | use `SliverQuiltedGrid` or `SliverWovenGrid` |
| `SliverPatternGridDelegate` | `PatternGridLayout` | return it from your own `SliverGridDelegate.getLayout` |
| `StaggeredGridView.countBuilder` (0.4 and older) | `MasonryGridView.count` | |

Behaviour changes worth knowing:

- **Quilted placement.** Each tile goes into the first free position (row
  by row) where it fits, in pattern order. Patterns like `[1x1, 1x1, 2x2]`
  with three columns no longer throw a `RangeError`: the wide tile moves to
  the next row. A pattern that does not fill a rectangle leaves holes, so
  design repeating patterns that do.
- **Pattern grids** stop scrolling at their last child.
- **Masonry after a resize.** A child that changes size keeps its column
  instead of reshuffling the grid. To get a fresh shortest-column layout (for
  example after replacing the whole data set), give the grid a new `Key`.

### Issues this package addresses

Checked against the open issues of flutter_staggered_grid_view on
2026-09-24. "Tested" means a test in `test/` reproduces the scenario.

| Issue | Problem | Here |
|---|---|---|
| [#244](https://github.com/letsar/flutter_staggered_grid_view/issues/244), [#330](https://github.com/letsar/flutter_staggered_grid_view/issues/330), [#327](https://github.com/letsar/flutter_staggered_grid_view/issues/327), [#356](https://github.com/letsar/flutter_staggered_grid_view/issues/356) | Jumps and jank when scrolling up a masonry grid | Index-keyed placement cache and upward growth with scroll correction. Tested |
| [#319](https://github.com/letsar/flutter_staggered_grid_view/issues/319) | Items move to another column when one resizes | Children keep their column. Tested |
| [#283](https://github.com/letsar/flutter_staggered_grid_view/issues/283) | Flicker when two columns have equal heights | Ties always go to the lowest column. Tested |
| [#265](https://github.com/letsar/flutter_staggered_grid_view/issues/265), [#338](https://github.com/letsar/flutter_staggered_grid_view/issues/338), [#286](https://github.com/letsar/flutter_staggered_grid_view/issues/286) | Several masonry slivers in one scroll view jump back | No scroll corrections while sizes are stable. Tested |
| [#340](https://github.com/letsar/flutter_staggered_grid_view/issues/340) | `findChildIndexCallback` breaks on reorder | Supported. Tested |
| [#360](https://github.com/letsar/flutter_staggered_grid_view/issues/360) | `AlignedGridView` freezes without `itemCount` | The child count is never searched for. Tested |
| [#320](https://github.com/letsar/flutter_staggered_grid_view/issues/320) | `AlignedGridView` rebuilds visible items on scroll | Items are individual sliver children. Tested |
| [#300](https://github.com/letsar/flutter_staggered_grid_view/issues/300) | Quilted grid scrolls past its last child | Exact `computeMaxScrollOffset`. Tested |
| [#221](https://github.com/letsar/flutter_staggered_grid_view/issues/221) | Quilted `RangeError` for some patterns | First-fit placement. Tested |
| [#263](https://github.com/letsar/flutter_staggered_grid_view/issues/263) | Right-to-left layouts | Every layout mirrors under RTL. Tested |
| [#105](https://github.com/letsar/flutter_staggered_grid_view/issues/105) | Changing `crossAxisCount` dynamically | The first visible child stays on screen. Tested |
| [#285](https://github.com/letsar/flutter_staggered_grid_view/issues/285) | `LateInitializationError` in `StaggeredGrid` | No late state; intrinsic sizing works. Tested |
| [#313](https://github.com/letsar/flutter_staggered_grid_view/issues/313), [#345](https://github.com/letsar/flutter_staggered_grid_view/issues/345) | Assertion and null errors inside the masonry layout | Different algorithm with no nullable placement state. Not reproduced, since the reports have no minimal repro |

## Limitations

- Masonry and aligned grids measure every child before the scroll position
  on a jump: `jumpTo(50000)` builds (and disposes) each child up to that
  point once. Later scrolling reuses the cache.
- When a masonry child that starts above the viewport changes size for good,
  the grid grows it upward and corrects the scroll offset. The other columns
  can then start with a gap at the very top of the grid. A child that changes
  size and back again, such as a placeholder replaced by an image of the same
  size, leaves no gap.
- Masonry placements are keyed by index, not by item identity. After an
  insert or a reorder, visible children take the column of their new index.
- `StaggeredGrid` builds and lays out all its children, so it suits small
  grids.
- Custom quilted repeat patterns and the staired layout of
  flutter_staggered_grid_view are not implemented.

## License

MIT. See [LICENSE](LICENSE).

Made by [Abdeldjalil Chougui](https://abdeldjalilchougui.biz/).
