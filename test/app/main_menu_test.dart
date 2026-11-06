import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teacher_team_dice/app/app.dart';
import 'package:teacher_team_dice/app/tool.dart';
import 'package:teacher_team_dice/app/tools.dart';
import 'package:teacher_team_dice/shared/database/app_database.dart';

void main() {
  // Pumps the full app at phone-portrait size with an in-memory database.
  Future<void> pumpApp(WidgetTester tester, {List<ToolDefinition>? tools}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: TeacherToolsApp(tools: tools),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('main menu lists every registered tool', (tester) async {
    await pumpApp(tester);
    expect(find.text(appName), findsOneWidget);
    for (final tool in appTools) {
      expect(find.text(tool.name), findsOneWidget);
      expect(find.text(tool.description), findsOneWidget);
    }
  });

  testWidgets('tapping a tool opens it and back returns to the menu', (tester) async {
    final tools = [
      ToolDefinition(
        id: 'alpha',
        name: 'Alpha',
        description: 'First test tool',
        icon: Icons.star,
        home: (_) => Scaffold(appBar: AppBar(title: const Text('Alpha home'))),
        routes: [GoRoute(path: 'detail', builder: (_, _) => const Text('Alpha detail'))],
      ),
      ToolDefinition(
        id: 'beta',
        name: 'Beta',
        description: 'Second test tool',
        icon: Icons.bolt,
        home: (_) => const Scaffold(body: Text('Beta home')),
      ),
    ];
    await pumpApp(tester, tools: tools);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha home'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Choose a tool'), findsOneWidget);
  });

  testWidgets('landscape content stays clear of the side notch', (tester) async {
    tester.view.physicalSize = const Size(874, 402);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(left: 62, right: 62, bottom: 21);
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const TeacherToolsApp(),
    ));
    await tester.pumpAndSettle();
    for (final tool in appTools) {
      final rect = tester.getRect(find.text(tool.name));
      expect(rect.left, greaterThanOrEqualTo(62));
      expect(rect.right, lessThanOrEqualTo(874 - 62));
    }
  });

  testWidgets('Team Dice opens from the menu', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Team Dice'));
    await tester.pumpAndSettle();
    expect(find.text('No classes yet. Create one to get started.'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });
}
