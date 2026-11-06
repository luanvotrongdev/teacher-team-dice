import 'package:drift/drift.dart';

import '../../../shared/database/app_database.dart';
import '../models/models.dart';

class QuizRepository {
  QuizRepository(this.db);
  final AppDatabase db;

  /// Saves a quiz and its words. Returns the quiz id.
  Future<int> createQuiz(String name, List<List<String>> columns) {
    return db.transaction(() async {
      final quizId = await db.into(db.lotteryQuizzes).insert(
            LotteryQuizzesCompanion.insert(name: name, createdAt: DateTime.now()),
          );
      await db.batch((b) {
        b.insertAll(db.lotteryWords, [
          for (var c = 0; c < columns.length; c++)
            for (var p = 0; p < columns[c].length; p++)
              LotteryWordsCompanion.insert(quizId: quizId, columnIndex: c, position: p, word: columns[c][p]),
        ]);
      });
      return quizId;
    });
  }

  Future<void> deleteQuiz(int id) => (db.delete(db.lotteryQuizzes)..where((q) => q.id.equals(id))).go();

  Future<List<Quiz>> listQuizzes() async {
    final rows = await (db.select(db.lotteryQuizzes)..orderBy([(q) => OrderingTerm.desc(q.createdAt)])).get();
    return [for (final r in rows) _toQuiz(r, await _words(r.id))];
  }

  Future<Quiz?> getQuiz(int id) async {
    final row = await (db.select(db.lotteryQuizzes)..where((q) => q.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toQuiz(row, await _words(id));
  }

  Future<List<LotteryWordRow>> _words(int quizId) => (db.select(db.lotteryWords)
        ..where((w) => w.quizId.equals(quizId))
        ..orderBy([(w) => OrderingTerm.asc(w.columnIndex), (w) => OrderingTerm.asc(w.position)]))
      .get();

  Quiz _toQuiz(LotteryQuizRow row, List<LotteryWordRow> words) {
    final columns = <int, List<String>>{};
    for (final w in words) {
      columns.putIfAbsent(w.columnIndex, () => []).add(w.word);
    }
    final keys = columns.keys.toList()..sort();
    return Quiz(id: row.id, name: row.name, createdAt: row.createdAt, columns: [for (final k in keys) columns[k]!]);
  }
}
