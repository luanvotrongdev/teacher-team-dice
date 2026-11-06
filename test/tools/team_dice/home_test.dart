import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teacher_team_dice/app/app.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';
import 'package:teacher_team_dice/tools/team_dice/data/class_repository.dart';
import 'package:teacher_team_dice/tools/team_dice/models/models.dart';

void main() {
  testWidgets('deleting a saved class removes it from the list', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.runAsync(() async {
      final repo = ClassRepository(db);
      final id = await repo.createClass('Physics', ['A', 'B'], [const GroupDraft(name: 'G1', project: '')]);
      final c = (await repo.getClass(id))!;
      await repo.saveAssignment(id, {c.groups.single.id: [for (final s in c.students) s.id]});
    });

    Future<void> settleDb() async {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const TeacherToolsApp(),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Team Dice'));
    await settleDb();
    await tester.tap(find.text('Physics'));
    await settleDb();

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settleDb();
    expect(find.text('Physics'), findsNothing);
    expect(find.text('No classes yet. Create one to get started.'), findsOneWidget);
  });
}
