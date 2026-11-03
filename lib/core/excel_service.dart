import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../models/models.dart';

class ExcelImportException implements Exception {
  ExcelImportException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _headerWords = {'name', 'student', 'students', 'student name', 'họ tên', 'họ và tên', 'tên'};

/// Reads student names from column A of the first sheet. Skips a header row.
List<String> parseStudents(Uint8List bytes) {
  final Excel book;
  try {
    book = Excel.decodeBytes(bytes);
  } catch (_) {
    throw ExcelImportException('Could not read this file. Please choose a valid .xlsx file.');
  }
  if (book.tables.isEmpty) throw ExcelImportException('The workbook has no sheets.');
  final sheet = book.tables.values.first;
  final names = <String>[];
  for (final row in sheet.rows) {
    if (row.isEmpty) continue;
    final text = row.first?.value?.toString().trim() ?? '';
    if (text.isNotEmpty) names.add(text);
  }
  if (names.isNotEmpty && _headerWords.contains(names.first.toLowerCase())) {
    names.removeAt(0);
  }
  if (names.isEmpty) throw ExcelImportException('No student names found in column A.');
  return names;
}

/// Builds an .xlsx with a "Groups" and a "Summary" sheet.
Uint8List buildExport(ClassModel c) {
  final book = Excel.createExcel();
  final groups = book['Groups'];
  groups.appendRow([TextCellValue('Group'), TextCellValue('Project'), TextCellValue('#'), TextCellValue('Student')]);
  final summary = book['Summary'];
  summary.appendRow([TextCellValue('Group'), TextCellValue('Project'), TextCellValue('Members')]);
  for (final g in c.groups) {
    for (var i = 0; i < g.members.length; i++) {
      groups.appendRow([
        TextCellValue(g.name),
        TextCellValue(g.project),
        IntCellValue(i + 1),
        TextCellValue(g.members[i].name),
      ]);
    }
    summary.appendRow([TextCellValue(g.name), TextCellValue(g.project), IntCellValue(g.members.length)]);
  }
  book.delete('Sheet1');
  book.setDefaultSheet('Groups');
  final out = book.encode();
  if (out == null) throw StateError('Failed to encode workbook');
  return Uint8List.fromList(out);
}
