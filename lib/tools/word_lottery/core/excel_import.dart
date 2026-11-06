import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/models.dart';

class QuizImportException implements Exception {
  QuizImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads the workbook's one sheet of words. Each column is a list of words.
///
/// Cells are trimmed. Rows and columns that are completely empty are removed.
/// Blank sheets are ignored, so a stray empty "Sheet2" doesn't block the import,
/// but two sheets with content are rejected.
QuizDraft parseQuizSheet(Uint8List bytes) {
  final Excel book;
  try {
    book = Excel.decodeBytes(bytes);
  } catch (_) {
    throw QuizImportException('Could not read this file. Please choose a valid .xlsx file.');
  }

  final filled = <String, List<List<String>>>{};
  for (final MapEntry(key: name, value: sheet) in book.tables.entries) {
    final grid = [
      for (final row in sheet.rows) [for (final cell in row) cell?.value?.toString().trim() ?? ''],
    ];
    if (grid.any((r) => r.any((c) => c.isNotEmpty))) filled[name] = grid;
  }
  if (filled.isEmpty) throw QuizImportException('The file has no words in it.');
  if (filled.length > 1) {
    throw QuizImportException(
      'The file must have only one sheet with words. Found ${filled.length}: ${filled.keys.join(', ')}.',
    );
  }

  final grid = filled.values.single;
  final width = grid.fold(0, (w, r) => r.length > w ? r.length : w);
  String cell(List<String> r, int c) => c < r.length ? r[c] : '';
  final keptRows = [for (final r in grid) if (r.any((c) => c.isNotEmpty)) r];
  final keptCols = [
    for (var c = 0; c < width; c++)
      if (keptRows.any((r) => cell(r, c).isNotEmpty)) c,
  ];

  return QuizDraft(
    rows: [
      for (final r in keptRows) [for (final c in keptCols) cell(r, c)],
    ],
    columns: [
      for (final c in keptCols) [for (final r in keptRows) if (cell(r, c).isNotEmpty) cell(r, c)],
    ],
  );
}
