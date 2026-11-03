import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'class_repository.dart';
import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<ClassRepository>((ref) => ClassRepository(ref.watch(databaseProvider)));

final classListProvider = FutureProvider.autoDispose<List<ClassModel>>(
  (ref) => ref.watch(repositoryProvider).listClasses(),
);

final classProvider = FutureProvider.autoDispose.family<ClassModel?, int>(
  (ref, id) => ref.watch(repositoryProvider).getClass(id),
);
