import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/tools/word_lottery/features/play/play_screen.dart';

void main() {
  const columns = [
    ['I', 'You', 'Our team'],
    ['want to buy', 'design', 'sell'],
    ['a new phone', 'a coffee brand', 'a bike'],
    ['in Hanoi', 'online', 'at school'],
  ];

  Future<List<Offset>> drawAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LotteryBoard(columns: columns, random: Random(1))),
    ));
    await tester.tap(find.text('Lottery'));
    await tester.pump(LotteryBoard.rollDuration + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    return [for (var i = 1; i <= columns.length; i++) tester.getCenter(find.text('Column $i'))];
  }

  testWidgets('landscape lays the words out in one row', (tester) async {
    final labels = await drawAt(tester, const Size(874, 402));
    for (var i = 1; i < labels.length; i++) {
      expect(labels[i].dy, labels[0].dy, reason: 'Column ${i + 1} is on the same row');
      expect(labels[i].dx, greaterThan(labels[i - 1].dx));
    }
    // All four fit across the screen without scrolling.
    expect(labels.last.dx, lessThan(874));
  });

  testWidgets('portrait stacks the words in one column', (tester) async {
    final labels = await drawAt(tester, const Size(390, 844));
    for (var i = 1; i < labels.length; i++) {
      expect(labels[i].dx, labels[0].dx, reason: 'Column ${i + 1} is in the same column');
      expect(labels[i].dy, greaterThan(labels[i - 1].dy));
    }
  });

  testWidgets('many columns in landscape scroll sideways instead of squeezing', (tester) async {
    tester.view.physicalSize = const Size(874, 402);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final many = [for (var i = 0; i < 10; i++) ['word $i']];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LotteryBoard(columns: many))));
    expect(find.byType(Scrollable), findsNWidgets(2)); // vertical page + horizontal row
    expect(tester.getSize(find.byType(Card).first).width, greaterThanOrEqualTo(140));
  });
}
