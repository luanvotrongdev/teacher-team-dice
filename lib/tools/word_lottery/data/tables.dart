import 'package:drift/drift.dart';

// Word Lottery tables. They are registered in the shared AppDatabase.
// Prefixed with "Lottery" so they can't clash with other tools' tables.
// Class names map to SQL table names, so renaming one would orphan saved data.

@DataClassName('LotteryQuizRow')
class LotteryQuizzes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// One word in one column of a quiz. Words keep their top-to-bottom order via [position].
@DataClassName('LotteryWordRow')
class LotteryWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get quizId => integer().references(LotteryQuizzes, #id, onDelete: KeyAction.cascade)();
  IntColumn get columnIndex => integer()();
  IntColumn get position => integer()();
  TextColumn get word => text()();
}
