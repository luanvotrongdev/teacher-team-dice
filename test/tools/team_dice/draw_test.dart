import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/tools/team_dice/data/class_repository.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';
import 'package:teacher_team_dice/tools/team_dice/data/providers.dart';
import 'package:teacher_team_dice/tools/team_dice/features/draw/draw_screen.dart';
import 'package:teacher_team_dice/tools/team_dice/models/models.dart';

/// Runs the full draw at [size], presses Save, and returns the saved group sizes.
Future<List<int>> _drawAndSave(WidgetTester tester, Size size, {required int students, required int groups}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final repo = ClassRepository(db);
  final id = await repo.createClass(
    'C',
    [for (var i = 1; i <= students; i++) 'Student $i'],
    [for (var i = 1; i <= groups; i++) GroupDraft(name: 'Group $i', project: 'P$i')],
  );

  await tester.pumpWidget(ProviderScope(
    overrides: [repositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: DrawScreen(classId: id)),
  ));
  await tester.pump(const Duration(milliseconds: 100));
  expect(find.text('Save'), findsNothing);

  await tester.pump(const Duration(milliseconds: 3200));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Save'), findsOneWidget);

  await tester.tap(find.text('Save'));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  final c = (await tester.runAsync(() => repo.getClass(id)))!;
  return c.groups.map((g) => g.members.length).toList()..sort();
}

void main() {
  testWidgets('draw animation finishes in ~3s and Save persists groups', (tester) async {
    expect(await _drawAndSave(tester, const Size(1200, 900), students: 14, groups: 3), [4, 5, 5]);
  });

  testWidgets('draw works on a portrait phone with actions in a bottom bar', (tester) async {
    final sizes = await _drawAndSave(tester, const Size(390, 844), students: 59, groups: 6);
    expect(sizes, [9, 10, 10, 10, 10, 10]);
    expect(find.text('View / Export'), findsOneWidget);
  });
}
