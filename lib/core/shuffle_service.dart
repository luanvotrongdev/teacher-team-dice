import 'dart:math';

/// Shuffles [items] and deals them round-robin into [groupCount] buckets,
/// so bucket sizes differ by at most one.
List<List<T>> assignEvenly<T>(List<T> items, int groupCount, {Random? random}) {
  assert(groupCount > 0);
  final shuffled = List<T>.of(items)..shuffle(random);
  final groups = List.generate(groupCount, (_) => <T>[]);
  for (var i = 0; i < shuffled.length; i++) {
    groups[i % groupCount].add(shuffled[i]);
  }
  return groups;
}
