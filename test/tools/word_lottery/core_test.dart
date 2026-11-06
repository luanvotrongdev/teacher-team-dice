import 'dart:math';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';
import 'package:teacher_team_dice/tools/word_lottery/core/excel_import.dart';
import 'package:teacher_team_dice/tools/word_lottery/core/lottery.dart';
import 'package:teacher_team_dice/tools/word_lottery/data/quiz_repository.dart';

/// Builds an .xlsx. [sheets] maps sheet name -> rows; null cells stay empty.
Uint8List book(Map<String, List<List<String?>>> sheets) {
  final b = Excel.createExcel();
  for (final MapEntry(key: name, value: rows) in sheets.entries) {
    final s = b[name];
    for (final r in rows) {
      s.appendRow([for (final v in r) v == null ? null : TextCellValue(v)]);
    }
  }
  if (!sheets.containsKey('Sheet1')) b.delete('Sheet1');
  return Uint8List.fromList(b.encode()!);
}

void main() {
  test('parseQuizSheet trims cells and drops empty rows and columns', () {
    final d = parseQuizSheet(book({
      'Sheet1': [
        [null, null, null, null],
        [null, ' I ', null, 'apples'],
        [null, 'You', null, null],
        [null, '   ', null, null],
        [null, 'They', null, 'pears '],
      ],
    }));
    expect(d.rows, [
      ['I', 'apples'],
      ['You', ''],
      ['They', 'pears'],
    ]);
    expect(d.columns, [
      ['I', 'You', 'They'],
      ['apples', 'pears'],
    ]);
    expect(d.wordCount, 5);
  });

  test('parseQuizSheet ignores blank extra sheets but rejects two filled ones', () {
    final ok = parseQuizSheet(book({
      'Words': [
        ['a', 'b'],
      ],
      'Sheet2': [],
    }));
    expect(ok.columns, [
      ['a'],
      ['b'],
    ]);
    expect(
      () => parseQuizSheet(book({
        'A': [
          ['x'],
        ],
        'B': [
          ['y'],
        ],
      })),
      throwsA(isA<QuizImportException>().having((e) => e.message, 'message', contains('only one sheet'))),
    );
  });

  test('parseQuizSheet rejects empty and invalid files', () {
    expect(
      () => parseQuizSheet(book({
        'Sheet1': [
          [null, ' '],
        ],
      })),
      throwsA(isA<QuizImportException>()),
    );
    expect(() => parseQuizSheet(Uint8List.fromList([1, 2, 3])), throwsA(isA<QuizImportException>()));
  });

  test('drawCombination takes one word per column and avoids repeating the last one', () {
    final columns = [
      ['I', 'You'],
      ['eat'],
      ['apples', 'pears', 'rice'],
    ];
    final rng = Random(1);
    var last = drawCombination(columns, rng);
    for (var i = 0; i < 50; i++) {
      expect(last.length, 3);
      for (var c = 0; c < 3; c++) {
        expect(columns[c], contains(last[c]));
      }
      final next = drawCombination(columns, rng, previous: last);
      expect(next, isNot(equals(last)));
      last = next;
    }
    // With only one possible combination it returns that instead of looping forever.
    expect(drawCombination([['a'], ['b']], rng, previous: ['a', 'b']), ['a', 'b']);
  });

  test('repository saves, reloads in order and deletes with words', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = QuizRepository(db);
    final id = await repo.createQuiz('Q1', [
      ['I', 'You', 'They'],
      ['apples', 'pears'],
    ]);
    final q = (await repo.getQuiz(id))!;
    expect(q.name, 'Q1');
    expect(q.columns, [
      ['I', 'You', 'They'],
      ['apples', 'pears'],
    ]);
    expect((await repo.listQuizzes()).single.wordCount, 5);
    await repo.deleteQuiz(id);
    expect(await repo.getQuiz(id), isNull);
    expect(await db.select(db.lotteryWords).get(), isEmpty);
  });

  test('a database from before Word Lottery (schema 1) gets the new tables', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE classes (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL, created_at INTEGER NOT NULL)');
      raw.execute("INSERT INTO classes (name, created_at) VALUES ('Old class', 0)");
      raw.userVersion = 1;
    }));
    addTearDown(db.close);
    final id = await QuizRepository(db).createQuiz('New', [
      ['a'],
    ]);
    expect((await QuizRepository(db).getQuiz(id))!.columns, [
      ['a'],
    ]);
    expect((await db.select(db.classes).get()).single.name, 'Old class');
  });
}
