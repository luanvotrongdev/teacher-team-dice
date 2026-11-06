import 'package:drift/drift.dart';

import '../models/models.dart';
import '../../../shared/database/app_database.dart' hide Student;

class ClassRepository {
  ClassRepository(this.db);
  final AppDatabase db;

  /// Creates a class with its students and (empty) groups. Returns the class id.
  Future<int> createClass(String name, List<String> students, List<GroupDraft> groups) {
    return db.transaction(() async {
      final classId = await db.into(db.classes).insert(
            ClassesCompanion.insert(name: name, createdAt: DateTime.now()),
          );
      for (var i = 0; i < students.length; i++) {
        await db.into(db.students).insert(
              StudentsCompanion.insert(classId: classId, name: students[i], orderIndex: i),
            );
      }
      for (var i = 0; i < groups.length; i++) {
        await db.into(db.groups).insert(
              GroupsCompanion.insert(
                classId: classId,
                name: groups[i].name,
                project: groups[i].project,
                orderIndex: i,
              ),
            );
      }
      return classId;
    });
  }

  /// Replaces all memberships; [assignment] maps group id -> ordered student ids.
  Future<void> saveAssignment(int classId, Map<int, List<int>> assignment) {
    return db.transaction(() async {
      final groupIds = (await (db.select(db.groups)..where((g) => g.classId.equals(classId))).get())
          .map((g) => g.id)
          .toList();
      await (db.delete(db.members)..where((m) => m.groupId.isIn(groupIds))).go();
      for (final entry in assignment.entries) {
        for (var i = 0; i < entry.value.length; i++) {
          await db.into(db.members).insert(
                MembersCompanion.insert(groupId: entry.key, studentId: entry.value[i], position: i),
              );
        }
      }
    });
  }

  Future<void> deleteClass(int id) => (db.delete(db.classes)..where((c) => c.id.equals(id))).go();

  Future<List<ClassModel>> listClasses() async {
    final rows = await (db.select(db.classes)..orderBy([(c) => OrderingTerm.desc(c.createdAt)])).get();
    final result = <ClassModel>[];
    for (final r in rows) {
      final c = await getClass(r.id);
      if (c != null) result.add(c);
    }
    return result;
  }

  Future<ClassModel?> getClass(int id) async {
    final row = await (db.select(db.classes)..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final studentRows = await (db.select(db.students)
          ..where((s) => s.classId.equals(id))
          ..orderBy([(s) => OrderingTerm.asc(s.orderIndex)]))
        .get();
    final students = {for (final s in studentRows) s.id: Student(id: s.id, name: s.name)};
    final groupRows = await (db.select(db.groups)
          ..where((g) => g.classId.equals(id))
          ..orderBy([(g) => OrderingTerm.asc(g.orderIndex)]))
        .get();
    final groups = <GroupModel>[];
    for (final g in groupRows) {
      final memberRows = await (db.select(db.members)
            ..where((m) => m.groupId.equals(g.id))
            ..orderBy([(m) => OrderingTerm.asc(m.position)]))
          .get();
      groups.add(GroupModel(
        id: g.id,
        name: g.name,
        project: g.project,
        members: [
          for (final m in memberRows)
            if (students[m.studentId] != null) students[m.studentId]!,
        ],
      ));
    }
    return ClassModel(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      students: students.values.toList(),
      groups: groups,
    );
  }
}
