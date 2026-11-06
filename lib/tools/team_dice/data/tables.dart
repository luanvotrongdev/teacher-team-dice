import 'package:drift/drift.dart';

// Team Dice tables. They are registered in the shared AppDatabase.
// Class names map to SQL table names, so renaming one would orphan saved data.

class Classes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();
}

class Groups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get classId => integer().references(Classes, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get project => text()();
  IntColumn get orderIndex => integer()();
}

class Members extends Table {
  IntColumn get groupId => integer().references(Groups, #id, onDelete: KeyAction.cascade)();
  IntColumn get studentId => integer().references(Students, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {groupId, studentId};
}
