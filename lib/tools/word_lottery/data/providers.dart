import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/database/app_database.dart';
import '../models/models.dart';
import 'quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) => QuizRepository(ref.watch(databaseProvider)));

final quizListProvider = FutureProvider.autoDispose<List<Quiz>>(
  (ref) => ref.watch(quizRepositoryProvider).listQuizzes(),
);

final quizProvider = FutureProvider.autoDispose.family<Quiz?, int>(
  (ref, id) => ref.watch(quizRepositoryProvider).getQuiz(id),
);

typedef PickedFile = ({String name, Uint8List bytes});

/// Opens the system picker for an .xlsx file. Returns null if the user cancels.
/// A provider so tests can hand in a file without the platform picker.
final quizFilePickerProvider = Provider<Future<PickedFile?> Function()>((ref) => () async {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (file == null) return null;
      return (name: file.name, bytes: await file.readAsBytes());
    });
