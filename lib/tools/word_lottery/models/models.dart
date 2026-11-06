/// A saved quiz: a name plus columns of words. Each column holds its words top to bottom.
class Quiz {
  const Quiz({required this.id, required this.name, required this.createdAt, required this.columns});
  final int id;
  final String name;
  final DateTime createdAt;
  final List<List<String>> columns;

  int get wordCount => columns.fold(0, (n, c) => n + c.length);
}

/// What an Excel import produced, shown on the confirmation screen before saving.
class QuizDraft {
  const QuizDraft({required this.rows, required this.columns});

  /// The sheet after trimming empty rows and columns. Cells are '' where the sheet had a gap.
  final List<List<String>> rows;

  /// The words in each column, top to bottom, gaps skipped. This is what gets saved.
  final List<List<String>> columns;

  int get wordCount => columns.fold(0, (n, c) => n + c.length);
}
