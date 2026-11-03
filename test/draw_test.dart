import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/data/class_repository.dart';
import 'package:teacher_team_dice/data/database.dart';
import 'package:teacher_team_dice/data/providers.dart';
import 'package:teacher_team_dice/features/draw/draw_screen.dart';
import 'package:teacher_team_dice/models/models.dart';

void main() {
  testWidgets('draw animation finishes in ~3s and Save persists groups', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ClassRepository(db);
    final id = await repo.createClass(
      'C',
      [for (var i = 1; i <= 14; i++) 'Student $i'],
      [for (var i = 1; i <= 3; i++) GroupDraft(name: 'Group $i', project: 'P$i')],
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
    expect(c.groups.map((g) => g.members.length).toList()..sort(), [4, 5, 5]);
  });
}
