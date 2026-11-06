import 'dart:math';

/// Picks one random word from every column.
///
/// When [previous] is given and another combination exists, the result differs
/// from it, so pressing Lottery always shows something new.
List<String> drawCombination(List<List<String>> columns, Random rng, {List<String>? previous}) {
  List<String> pick() => [for (final c in columns) c[rng.nextInt(c.length)]];
  final canChange = columns.any((c) => c.toSet().length > 1);
  var result = pick();
  if (previous != null && canChange) {
    while (_same(result, previous)) {
      result = pick();
    }
  }
  return result;
}

bool _same(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
