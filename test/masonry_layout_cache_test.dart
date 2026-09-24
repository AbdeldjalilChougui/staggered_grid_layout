import 'package:flutter_test/flutter_test.dart';
import 'package:staggered_grid_layout/src/rendering/masonry_layout_cache.dart';

void main() {
  group('MasonryLayoutCache placement', () {
    test('places each item in the shortest column', () {
      final cache = MasonryLayoutCache()..reset(3, 0, 100);
      for (final h in <double>[100, 50, 80, 30, 60]) {
        cache.append(h);
      }
      // col0: 100 | col1: 50 | col2: 80
      // item3 (30) -> col1 (50) ends at 80
      // item4 (60) -> col1 again? col1 ends 80, col2 ends 80 -> tie -> col1.
      expect(cache[0].column, 0);
      expect(cache[1].column, 1);
      expect(cache[2].column, 2);
      expect(cache[3].column, 1);
      expect(cache[3].offset, 50);
      expect(cache[4].column, 1);
      expect(cache[4].offset, 80);
    });

    test('breaks ties by the lowest column index', () {
      final cache = MasonryLayoutCache()..reset(4, 0, 100);
      for (var i = 0; i < 8; i++) {
        cache.append(100);
      }
      expect([for (var i = 0; i < 8; i++) cache[i].column],
          [0, 1, 2, 3, 0, 1, 2, 3]);
      expect(cache[4].offset, 100);
    });

    test('treats floating point near-ties as ties', () {
      final cache = MasonryLayoutCache()..reset(2, 0, 100);
      cache.append(0.1 + 0.2); // 0.30000000000000004
      cache.append(0.3);
      cache.append(10);
      expect(cache[2].column, 0);
    });

    test('adds main axis spacing between items of a column', () {
      final cache = MasonryLayoutCache()..reset(2, 8, 100);
      cache
        ..append(100)
        ..append(40)
        ..append(10);
      expect(cache[2].column, 1);
      expect(cache[2].offset, 48);
      expect(cache.maxTrailing, 100);
    });
  });

  group('MasonryLayoutCache resize', () {
    MasonryLayoutCache build() {
      final cache = MasonryLayoutCache()..reset(2, 0, 100);
      for (final h in <double>[100, 60, 50, 70, 40, 40]) {
        cache.append(h);
      }
      return cache;
    }

    test('growing downward shifts later items of the same column only', () {
      final cache = build();
      final before = [
        for (var i = 0; i < cache.length; i++)
          (column: cache[i].column, offset: cache[i].offset),
      ];
      final column = cache[1].column;
      cache.resize(1, 80, anchorTrailing: false);
      for (var i = 0; i < cache.length; i++) {
        expect(cache[i].column, before[i].column, reason: 'item $i column');
        if (i > 1 && cache[i].column == column) {
          expect(cache[i].offset, before[i].offset + 20);
        } else if (i != 1) {
          expect(cache[i].offset, before[i].offset);
        }
      }
      expect(cache[1].extent, 80);
    });

    test('growing upward keeps the trailing edge and later items fixed', () {
      final cache = build();
      final item = 3;
      final trailing = cache[item].trailing;
      final later = [
        for (var i = item + 1; i < cache.length; i++) cache[i].offset,
      ];
      cache.resize(item, cache[item].extent + 25, anchorTrailing: true);
      expect(cache[item].trailing, trailing);
      expect([for (var i = item + 1; i < cache.length; i++) cache[i].offset],
          later);
      // The column now starts above zero.
      expect(cache.minOffset, lessThan(0));
    });

    test('normalize shifts everything so the top is at zero', () {
      final cache = build();
      cache.resize(3, cache[3].extent + 25, anchorTrailing: true);
      final shift = cache.normalize();
      expect(shift, 25);
      expect(cache.minOffset, 0);
    });

    test('truncate drops entries and recomputes column ends', () {
      final cache = build();
      cache.truncate(2);
      expect(cache.length, 2);
      final next = cache.append(10);
      expect(next.column, 1);
      expect(next.offset, 60);
    });
  });

  group('MasonryLayoutCache queries', () {
    test('first and last indexes intersecting a range', () {
      final cache = MasonryLayoutCache()..reset(2, 0, 100);
      for (var i = 0; i < 20; i++) {
        cache.append(100);
      }
      expect(cache.firstIndexEndingAfter(250), 4);
      expect(cache.lastIndexStartingBefore(450), 9);
      expect(cache.firstIndexEndingAfter(5000), isNull);
    });
  });
}
