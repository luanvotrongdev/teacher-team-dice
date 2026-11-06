import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/database/app_database.dart';
import '../models/models.dart';
import 'class_repository.dart';

final repositoryProvider = Provider<ClassRepository>((ref) => ClassRepository(ref.watch(databaseProvider)));

final classListProvider = FutureProvider.autoDispose<List<ClassModel>>(
  (ref) => ref.watch(repositoryProvider).listClasses(),
);

final classProvider = FutureProvider.autoDispose.family<ClassModel?, int>(
  (ref, id) => ref.watch(repositoryProvider).getClass(id),
);
