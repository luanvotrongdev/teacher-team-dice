class Student {
  const Student({required this.id, required this.name});
  final int id;
  final String name;
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.project,
    required this.members,
  });
  final int id;
  final String name;
  final String project;
  final List<Student> members;
}

class ClassModel {
  const ClassModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.students,
    required this.groups,
  });
  final int id;
  final String name;
  final DateTime createdAt;
  final List<Student> students;
  final List<GroupModel> groups;

  bool get hasResult => groups.any((g) => g.members.isNotEmpty);
}

/// Input for a group while creating a class.
class GroupDraft {
  const GroupDraft({required this.name, required this.project});
  final String name;
  final String project;
}
