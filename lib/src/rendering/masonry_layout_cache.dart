import 'dart:math' as math;

/// Tolerance used when comparing main axis offsets.
///
/// Two column ends closer than this are treated as equal, so ties are always
/// broken by the lowest column index even with floating point noise.
const double kMasonryTolerance = 1e-7;

/// The cached placement of one masonry child.
class MasonryEntry {
  /// Creates an entry.
  MasonryEntry(this.column, this.offset, this.extent);

  /// The column (cross axis track) the child is placed in.
  final int column;

  /// The main axis offset of the leading edge of the child.
  double offset;

  /// The main axis extent of the child.
  double extent;

  /// The main axis offset of the trailing edge of the child.
  double get trailing => offset + extent;

  @override
  String toString() => 'MasonryEntry(column: $column, offset: $offset, '
      'extent: $extent)';
}

/// An index-keyed cache of masonry placements.
///
/// Entries always form a prefix: entry `i` exists for every `i < length`.
/// A child keeps its column for as long as it is cached, so a child that
/// changes size only moves the children of its own column, and scrolling back
/// up reuses the exact positions computed on the way down.
class MasonryLayoutCache {
  final List<MasonryEntry> _entries = <MasonryEntry>[];
  List<double> _nextStart = const <double>[];
  List<bool> _hasItems = const <bool>[];
  double _extentSum = 0;

  int _crossAxisCount = 0;
  double _mainAxisSpacing = 0;
  double _crossAxisExtent = -1;

  /// The number of columns of the current layout.
  int get crossAxisCount => _crossAxisCount;

  /// Whether this cache was computed for the given layout parameters.
  bool matches(int crossAxisCount, double mainAxisSpacing,
          double childCrossAxisExtent) =>
      crossAxisCount == _crossAxisCount &&
      mainAxisSpacing == _mainAxisSpacing &&
      (childCrossAxisExtent - _crossAxisExtent).abs() <= kMasonryTolerance;

  /// Drops every entry and starts a new layout.
  void reset(
      int crossAxisCount, double mainAxisSpacing, double childCrossAxisExtent) {
    _crossAxisCount = math.max(1, crossAxisCount);
    _mainAxisSpacing = mainAxisSpacing;
    _crossAxisExtent = childCrossAxisExtent;
    _entries.clear();
    _extentSum = 0;
    _nextStart = List<double>.filled(_crossAxisCount, 0);
    _hasItems = List<bool>.filled(_crossAxisCount, false);
  }

  /// The number of cached entries.
  int get length => _entries.length;

  /// The entry of the child at [index].
  MasonryEntry operator [](int index) => _entries[index];

  /// The main axis offset at which the next appended child would start.
  double get minNextStart {
    var best = double.infinity;
    for (final value in _nextStart) {
      if (value < best) best = value;
    }
    return best;
  }

  /// The largest trailing edge of all entries, or 0 when empty.
  double get maxTrailing {
    var best = 0.0;
    for (var c = 0; c < _crossAxisCount; c++) {
      if (_hasItems[c]) {
        best = math.max(best, _nextStart[c] - _mainAxisSpacing);
      }
    }
    return best;
  }

  /// The smallest leading edge of all entries, or 0 when empty.
  double get minOffset {
    if (_entries.isEmpty) return 0;
    var best = double.infinity;
    final seen = List<bool>.filled(_crossAxisCount, false);
    var remaining = _crossAxisCount;
    for (final entry in _entries) {
      if (seen[entry.column]) continue;
      seen[entry.column] = true;
      best = math.min(best, entry.offset);
      if (--remaining == 0) break;
    }
    return best;
  }

  /// The average main axis extent of the cached entries.
  double get averageExtent =>
      _entries.isEmpty ? 0 : _extentSum / _entries.length;

  /// Estimates the total main axis extent for [childCount] children.
  double estimateTotalExtent(int childCount) {
    final remaining = childCount - _entries.length;
    if (remaining <= 0) return maxTrailing;
    var columnSum = 0.0;
    for (final value in _nextStart) {
      columnSum += value;
    }
    final estimate =
        (columnSum + remaining * (averageExtent + _mainAxisSpacing)) /
                _crossAxisCount -
            _mainAxisSpacing;
    return math.max(maxTrailing, estimate);
  }

  /// Appends the next child, placing it in the shortest column.
  ///
  /// Ties are broken by the lowest column index.
  MasonryEntry append(double extent) {
    var column = 0;
    var best = _nextStart[0];
    for (var c = 1; c < _crossAxisCount; c++) {
      if (_nextStart[c] < best - kMasonryTolerance) {
        best = _nextStart[c];
        column = c;
      }
    }
    final entry = MasonryEntry(column, best, extent);
    _entries.add(entry);
    _extentSum += extent;
    _nextStart[column] = entry.trailing + _mainAxisSpacing;
    _hasItems[column] = true;
    return entry;
  }

  /// Drops every entry at or after [length].
  void truncate(int length) {
    if (length >= _entries.length) return;
    _entries.removeRange(math.max(0, length), _entries.length);
    _recompute();
  }

  /// Records that the child at [index] now has [extent].
  ///
  /// The child keeps its column. When [anchorTrailing] is false, the child
  /// grows or shrinks at its trailing edge and the later children of its
  /// column move with it. When [anchorTrailing] is true, the child keeps its
  /// trailing edge and the earlier children of its column move instead, so
  /// that content after it does not move. Use this for children that start
  /// above the visible area.
  void resize(int index, double extent, {required bool anchorTrailing}) {
    final entry = _entries[index];
    final delta = extent - entry.extent;
    if (delta == 0) return;
    _extentSum += delta;
    entry.extent = extent;
    if (anchorTrailing) {
      entry.offset -= delta;
      for (var i = 0; i < index; i++) {
        final other = _entries[i];
        if (other.column == entry.column) other.offset -= delta;
      }
    } else {
      for (var i = index + 1; i < _entries.length; i++) {
        final other = _entries[i];
        if (other.column == entry.column) other.offset += delta;
      }
    }
    _recompute();
  }

  /// Shifts every entry by [delta] along the main axis.
  void shift(double delta) {
    if (delta == 0) return;
    for (final entry in _entries) {
      entry.offset += delta;
    }
    _recompute();
  }

  /// Moves every entry so that the highest column starts at zero when some
  /// column starts above zero. Returns the applied shift (0 when none).
  double normalize() {
    final top = minOffset;
    if (top >= -kMasonryTolerance) return 0;
    shift(-top);
    return -top;
  }

  /// The smallest index whose trailing edge is after [offset], or null.
  int? firstIndexEndingAfter(double offset) {
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].trailing > offset + kMasonryTolerance) return i;
    }
    return null;
  }

  /// The largest index whose leading edge is before [offset], or null.
  int? lastIndexStartingBefore(double offset) {
    for (var i = _entries.length - 1; i >= 0; i--) {
      if (_entries[i].offset < offset - kMasonryTolerance) return i;
    }
    return null;
  }

  void _recompute() {
    _nextStart = List<double>.filled(_crossAxisCount, 0);
    _hasItems = List<bool>.filled(_crossAxisCount, false);
    _extentSum = 0;
    for (final entry in _entries) {
      _extentSum += entry.extent;
      _nextStart[entry.column] = entry.trailing + _mainAxisSpacing;
      _hasItems[entry.column] = true;
    }
  }
}
