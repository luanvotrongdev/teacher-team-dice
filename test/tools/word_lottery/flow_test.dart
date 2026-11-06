import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/app/app.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';
import 'package:teacher_team_dice/tools/word_lottery/data/providers.dart';
import 'package:teacher_team_dice/tools/word_lottery/features/play/play_screen.dart';

import 'core_test.dart' show book;

const _columns = [
  ['I', 'You', 'They'],
  ['eat', 'cook'],
  ['apples', 'pears', 'rice', 'soup'],
];

void main() {
  testWidgets('create a quiz from Excel, draw, then delete it (phone portrait)', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    // The sheet has an empty first row and an empty column B, which the import removes.
    final bytes = book({
      'Sheet1': [
        [null, null, null, null],
        for (var r = 0; r < 4; r++)
          [
            r < _columns[0].length ? _columns[0][r] : null,
            null,
            r < _columns[1].length ? _columns[1][r] : null,
            _columns[2][r],
          ],
      ],
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        quizFilePickerProvider.overrideWithValue(() async => (name: 'words.xlsx', bytes: bytes)),
      ],
      child: const TeacherToolsApp(),
    ));
    await tester.pumpAndSettle();

    Future<void> settleDb() async {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Word Lottery'));
    await tester.pumpAndSettle();
    await settleDb();
    expect(find.text('No quizzes yet. Create one to get started.'), findsOneWidget);

    await tester.tap(find.text('New quiz'));
    await tester.pumpAndSettle();

    // A name is required before importing.
    await tester.tap(find.text('Import words (.xlsx)'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz name is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Sentences');
    await tester.tap(find.text('Import words (.xlsx)'));
    await tester.pumpAndSettle();

    // Confirmation screen: trimmed to 3 columns, nothing saved yet.
    expect(find.text('Confirm words'), findsOneWidget);
    expect(find.text('3 columns · 9 words · from words.xlsx'), findsOneWidget);
    expect(find.text('Column 3 (4)'), findsOneWidget);
    expect(find.text('soup'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.lotteryQuizzes).get()), isEmpty);

    await tester.tap(find.text('Confirm'));
    await settleDb();

    // Play screen.
    expect(find.text('Sentences'), findsOneWidget);
    expect(find.text('Press Lottery to draw a combination'), findsOneWidget);
    await tester.tap(find.text('Lottery'));
    await tester.pump(LotteryBoard.rollDuration + const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final shown = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toSet();
    for (final column in _columns) {
      expect(column.where(shown.contains), hasLength(1), reason: 'one word from $column');
    }

    // Back to the list, which now shows the quiz, then reopen it.
    await tester.tap(find.byType(BackButton));
    await settleDb();
    expect(find.text('3 columns · 9 words'), findsOneWidget);
    await tester.tap(find.text('Sentences'));
    await settleDb();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleDb();
    expect(find.text('No quizzes yet. Create one to get started.'), findsOneWidget);
    expect(await tester.runAsync(() => db.select(db.lotteryWords).get()), isEmpty);
  });
}
