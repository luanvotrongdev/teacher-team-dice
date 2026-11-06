import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/tools/team_dice/core/excel_service.dart';
import 'package:teacher_team_dice/tools/team_dice/core/shuffle_service.dart';
import 'package:teacher_team_dice/tools/team_dice/data/class_repository.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';
import 'package:teacher_team_dice/tools/team_dice/models/models.dart';

import 'dart:typed_data';

Uint8List _book(List<String?> col) {
  final b = Excel.createExcel();
  final s = b['Sheet1'];
  for (final v in col) {
    s.appendRow([v == null ? null : TextCellValue(v)]);
  }
  return Uint8List.fromList(b.encode()!);
}

void main() {
  test('assignEvenly keeps sizes within one and loses nobody', () {
    final r = assignEvenly(List.generate(10, (i) => i), 3);
    expect(r.map((g) => g.length).toList()..sort(), [3, 3, 4]);
    expect(r.expand((g) => g).toSet().length, 10);
  });

  test('parseStudents skips header and blanks', () {
    expect(parseStudents(_book(['Name', 'An', null, ' Binh '])), ['An', 'Binh']);
    expect(parseStudents(_book(['An', 'Binh'])), ['An', 'Binh']);
    expect(() => parseStudents(_book(['Name'])), throwsA(isA<ExcelImportException>()));
    expect(() => parseStudents(Uint8List.fromList([1, 2, 3])), throwsA(isA<ExcelImportException>()));
  });

  test('repository save/reload and export', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = ClassRepository(db);
    final id = await repo.createClass('C1', ['A', 'B', 'C'], [
      const GroupDraft(name: 'G1', project: 'P1'),
      const GroupDraft(name: 'G2', project: 'P2'),
    ]);
    var c = (await repo.getClass(id))!;
    expect(c.hasResult, isFalse);
    await repo.saveAssignment(id, {
      c.groups[0].id: [c.students[0].id, c.students[2].id],
      c.groups[1].id: [c.students[1].id],
    });
    c = (await repo.getClass(id))!;
    expect(c.groups[0].members.map((s) => s.name), ['A', 'C']);
    final out = Excel.decodeBytes(buildExport(c));
    expect(out.tables['Groups']!.maxRows, 4);
    await repo.deleteClass(id);
    expect(await repo.getClass(id), isNull);
    await db.close();
  });
}
