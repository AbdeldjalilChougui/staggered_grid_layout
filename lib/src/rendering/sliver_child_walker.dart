import 'package:flutter/rendering.dart';

/// Index-based access to the children of a [RenderSliverMultiBoxAdaptor].
///
/// The adaptor keeps its children as a contiguous run of indexes. This mixin
/// lets a layout algorithm ask for "the child at index i" and takes care of
/// creating the children needed to keep the run contiguous.
mixin SliverChildWalker on RenderSliverMultiBoxAdaptor {
  /// The constraints used to lay out the child at [index].
  BoxConstraints childConstraintsFor(int index);

  /// Called after every child laid out by [obtainChild].
  void didLayoutChild(RenderBox child);

  /// The number of children currently in the child list.
  int countChildren() {
    var count = 0;
    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      count++;
    }
    return count;
  }

  /// The number of children in the child list whose index is below [index].
  int countChildrenBefore(int index) {
    var count = 0;
    for (RenderBox? child = firstChild;
        child != null;
        child = childAfter(child)) {
      if (indexOf(child) >= index) break;
      count++;
    }
    return count;
  }

  /// The number of children in the child list whose index is above [index].
  int countChildrenAfter(int index) {
    var count = 0;
    for (RenderBox? child = lastChild;
        child != null;
        child = childBefore(child)) {
      if (indexOf(child) <= index) break;
      count++;
    }
    return count;
  }

  /// Returns the child at [index], laid out, creating it (and every child
  /// needed to keep the child list contiguous) when necessary.
  ///
  /// Returns null when the child manager has no child at [index].
  RenderBox? obtainChild(int index) {
    if (firstChild == null) {
      if (!addInitialChild(index: index)) return null;
      final child = firstChild!;
      child.layout(childConstraintsFor(index), parentUsesSize: true);
      didLayoutChild(child);
      return child;
    }

    var firstIndex = indexOf(firstChild!);
    if (index < firstIndex) {
      RenderBox? child;
      while (firstIndex > index) {
        child = insertAndLayoutLeadingChild(
          childConstraintsFor(firstIndex - 1),
          parentUsesSize: true,
        );
        if (child == null) return null;
        didLayoutChild(child);
        firstIndex--;
      }
      return child;
    }

    RenderBox? previous;
    RenderBox? child = firstChild;
    while (child != null && indexOf(child) < index) {
      previous = child;
      child = childAfter(child);
    }
    if (child != null && indexOf(child) == index) {
      child.layout(childConstraintsFor(index), parentUsesSize: true);
      didLayoutChild(child);
      return child;
    }

    // Fill the hole between `previous` and `index`.
    var after = previous!;
    for (var i = indexOf(after) + 1; i <= index; i++) {
      final inserted = insertAndLayoutChild(
        childConstraintsFor(i),
        after: after,
        parentUsesSize: true,
      );
      if (inserted == null) return null;
      didLayoutChild(inserted);
      after = inserted;
    }
    return after;
  }
}
