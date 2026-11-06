import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tools/team_dice/data/tables.dart';
import '../../tools/word_lottery/data/tables.dart';

part 'app_database.g.dart';

/// The one on-device database for the whole app. Every tool registers its tables here,
/// so tools can share data later by reading each other's tables (or shared tables added here).
///
/// When a tool adds or changes tables: bump [schemaVersion], add a step to `onUpgrade`,
/// then run `dart run build_runner build`.
@DriftDatabase(tables: [
  // Team Dice
  Classes, Students, Groups, Members,
  // Word Lottery
  LotteryQuizzes, LotteryWords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ??
            driftDatabase(
              // Kept from the single-tool app so existing saved data still opens.
              name: 'teacher_team_dice',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ));

  // 1: Team Dice. 2: Word Lottery tables.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(lotteryQuizzes);
            await m.createTable(lotteryWords);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
