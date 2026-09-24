import 'package:flutter/material.dart';
import 'package:staggered_grid_layout/staggered_grid_layout.dart';

void main() => runApp(const DemoApp());

/// Demo app showing every layout of the package.
class DemoApp extends StatefulWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  bool _rtl = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'staggered_grid_layout',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      builder: (context, child) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: HomePage(
        rtl: _rtl,
        onRtlChanged: (value) => setState(() => _rtl = value),
      ),
    );
  }
}

/// A demo entry of the home page.
class Demo {
  /// Creates a demo entry.
  const Demo(this.title, this.subtitle, this.builder);

  /// Title shown in the list.
  final String title;

  /// One line description.
  final String subtitle;

  /// Builds the demo page body.
  final WidgetBuilder builder;
}

/// Every demo of the app.
final demos = <Demo>[
  Demo('Masonry', 'MasonryGridView.count, tap a tile to resize it',
      (_) => const MasonryDemo()),
  Demo(
      'Masonry (extent, horizontal)',
      'MasonryGridView.extent scrolling horizontally',
      (_) => const HorizontalMasonryDemo()),
  Demo('Aligned', 'AlignedGridView.count: rows match their tallest tile',
      (_) => const AlignedDemo()),
  Demo('Quilted', 'SliverQuiltedGrid with same, inverted and mirrored repeats',
      (_) => const QuiltedDemo()),
  Demo('Woven', 'SliverWovenGrid.count', (_) => const WovenDemo()),
  Demo('Staggered', 'StaggeredGrid with count, extent and fit tiles',
      (_) => const StaggeredDemo()),
  Demo('Mixed slivers', 'Several grids in one CustomScrollView',
      (_) => const MixedSliversDemo()),
];

/// Lists the demos.
class HomePage extends StatelessWidget {
  /// Creates the home page.
  const HomePage({super.key, required this.rtl, required this.onRtlChanged});

  /// Whether the app is right-to-left.
  final bool rtl;

  /// Switches the reading direction.
  final ValueChanged<bool> onRtlChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('staggered_grid_layout'),
        actions: [
          const Center(child: Text('RTL')),
          Switch(value: rtl, onChanged: onRtlChanged),
        ],
      ),
      body: ListView(
        children: [
          for (final demo in demos)
            ListTile(
              title: Text(demo.title),
              subtitle: Text(demo.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(demo.title)),
                    body: demo.builder(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A colored tile showing its index.
class Tile extends StatelessWidget {
  /// Creates a tile.
  const Tile(this.index, {super.key, this.extent, this.onTap});

  /// Index of the tile.
  final int index;

  /// Main axis extent, or null to fill the space given.
  final double? extent;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Colors.primaries[index % Colors.primaries.length];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: extent,
        decoration: BoxDecoration(
          color: color.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text('$index', style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

/// Deterministic tile heights between 80 and 220.
double heightFor(int id) => 80.0 + (id * 47) % 141;

/// Masonry grid with resizable tiles, inserts and shuffles.
class MasonryDemo extends StatefulWidget {
  /// Creates the demo.
  const MasonryDemo({super.key});

  @override
  State<MasonryDemo> createState() => _MasonryDemoState();
}

class _MasonryDemoState extends State<MasonryDemo> {
  final List<int> _ids = List<int>.generate(200, (i) => i);
  final Set<int> _expanded = <int>{};
  int _next = 200;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MasonryGridView.count(
          padding: const EdgeInsets.all(8),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          itemCount: _ids.length,
          findChildIndexCallback: (key) {
            final index = _ids.indexOf((key as ValueKey<int>).value);
            return index < 0 ? null : index;
          },
          itemBuilder: (context, i) {
            final id = _ids[i];
            return AnimatedSize(
              key: ValueKey<int>(id),
              duration: const Duration(milliseconds: 200),
              child: Tile(
                id,
                extent: heightFor(id) + (_expanded.contains(id) ? 120 : 0),
                onTap: () => setState(() {
                  if (!_expanded.remove(id)) _expanded.add(id);
                }),
              ),
            );
          },
        ),
        PositionedDirectional(
          end: 16,
          bottom: 16,
          child: Row(
            children: [
              FloatingActionButton.small(
                heroTag: 'insert',
                tooltip: 'Insert at the top',
                onPressed: () => setState(() => _ids.insert(0, _next++)),
                child: const Icon(Icons.add),
              ),
              const SizedBox(width: 8),
              FloatingActionButton.small(
                heroTag: 'shuffle',
                tooltip: 'Shuffle',
                onPressed: () => setState(_ids.shuffle),
                child: const Icon(Icons.shuffle),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Masonry grid scrolling horizontally, with rows derived from a maximum
/// extent.
class HorizontalMasonryDemo extends StatelessWidget {
  /// Creates the demo.
  const HorizontalMasonryDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.extent(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      maxCrossAxisExtent: 120,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: 150,
      itemBuilder: (context, i) => SizedBox(
        width: heightFor(i),
        child: Tile(i),
      ),
    );
  }
}

/// Aligned grid with text of different lengths.
class AlignedDemo extends StatelessWidget {
  /// Creates the demo.
  const AlignedDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return AlignedGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: 120,
      itemBuilder: (context, i) => Card(
        margin: EdgeInsets.zero,
        color: Colors.primaries[i % Colors.primaries.length].shade100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Item $i ${'word ' * ((i * 7) % 9)}'),
        ),
      ),
    );
  }
}

/// Quilted grid with a repeat pattern selector.
class QuiltedDemo extends StatefulWidget {
  /// Creates the demo.
  const QuiltedDemo({super.key});

  @override
  State<QuiltedDemo> createState() => _QuiltedDemoState();
}

class _QuiltedDemoState extends State<QuiltedDemo> {
  QuiltedGridRepeatPattern _repeat = QuiltedGridRepeatPattern.same;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<QuiltedGridRepeatPattern>(
              segments: [
                for (final value in QuiltedGridRepeatPattern.values)
                  ButtonSegment(value: value, label: Text(value.name)),
              ],
              selected: {_repeat},
              onSelectionChanged: (value) =>
                  setState(() => _repeat = value.first),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverQuiltedGrid.builder(
            crossAxisCount: 4,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            repeatPattern: _repeat,
            pattern: const [
              QuiltedGridTile(2, 2),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 1),
              QuiltedGridTile(1, 2),
            ],
            itemCount: 200,
            itemBuilder: (context, i) => Tile(i),
          ),
        ),
      ],
    );
  }
}

/// Woven grid.
class WovenDemo extends StatelessWidget {
  /// Creates the demo.
  const WovenDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverWovenGrid.count(
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
              (context, i) => Tile(i),
              childCount: 100,
            ),
          ),
        ),
      ],
    );
  }
}

/// Non-scrolling staggered grid inside a scroll view.
class StaggeredDemo extends StatelessWidget {
  /// Creates the demo.
  const StaggeredDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: const [
          StaggeredGridTile.count(
              crossAxisCellCount: 2, mainAxisCellCount: 2, child: Tile(0)),
          StaggeredGridTile.count(
              crossAxisCellCount: 2, mainAxisCellCount: 1, child: Tile(1)),
          StaggeredGridTile.count(
              crossAxisCellCount: 1, mainAxisCellCount: 1, child: Tile(2)),
          StaggeredGridTile.count(
              crossAxisCellCount: 1, mainAxisCellCount: 1, child: Tile(3)),
          StaggeredGridTile.extent(
              crossAxisCellCount: 4, mainAxisExtent: 60, child: Tile(4)),
          StaggeredGridTile.fit(
              crossAxisCellCount: 2, child: Tile(5, extent: 150)),
          StaggeredGridTile.count(
              crossAxisCellCount: 2, mainAxisCellCount: 1.5, child: Tile(6)),
        ],
      ),
    );
  }
}

/// Several grids and headers in one scroll view.
class MixedSliversDemo extends StatelessWidget {
  /// Creates the demo.
  const MixedSliversDemo({super.key});

  Widget _header(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(text),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _header('SliverMasonryGrid.count'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverMasonryGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: 20,
            itemBuilder: (context, i) => Tile(i, extent: heightFor(i)),
          ),
        ),
        _header('SliverAlignedGrid.extent'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverAlignedGrid.extent(
            maxCrossAxisExtent: 150,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: 12,
            itemBuilder: (context, i) => Tile(i, extent: 40.0 + (i % 3) * 30),
          ),
        ),
        _header('SliverMasonryGrid.extent'),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          sliver: SliverMasonryGrid.extent(
            maxCrossAxisExtent: 120,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childCount: 40,
            itemBuilder: (context, i) => Tile(i, extent: heightFor(i + 3)),
          ),
        ),
      ],
    );
  }
}
