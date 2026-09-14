import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../../auth/data/course_repository.dart';

/// Reads the organisation's participant file, CSV or Excel, into rows the
/// importer can check.
///
/// The organisation's own column headings are the ones that matter, so the
/// Urdu names are what the reader looks for. English equivalents are accepted
/// too, because a file exported by other software often carries those instead.
class ParticipantFile {
  const ParticipantFile._();

  /// Column headings understood for each field. Compared after normalisation,
  /// so spacing and diacritics in the heading do not matter.
  static const Map<String, List<String>> _headings = <String, List<String>>{
    'registration_number': <String>[
      'رقم تسجیل',
      'رقم التسجیل',
      'رجسٹریشن نمبر',
      'registration_number',
      'registration number',
      'reg no',
    ],
    'full_name': <String>[
      'نام مع ولدیت',
      'نام',
      'پورا نام',
      'full_name',
      'full name',
      'name',
    ],
    'course_start_date': <String>[
      'داخلہ ماہ',
      'داخلہ',
      'course_start_date',
      'course start',
    ],
    'course_period': <String>[
      'دورانیہ',
      'مدت',
      'course_period',
      'course period',
      'duration',
    ],
    'course_completion_date': <String>[
      'فراغت ماہ',
      'فراغت',
      'course_completion_date',
      'course completion',
    ],
  };

  /// Normalises a heading so spacing, diacritics and the zero-width joiners an
  /// Urdu keyboard inserts do not stop a column being recognised.
  static String normalise(String value) {
    return value
        .replaceAll(RegExp('[ً-ْٰ​-‏]'), '')
        .replaceAll(RegExp(r'[_\s]+'), ' ')
        .trim()
        .toLowerCase();
  }

  /// True when the file name looks like a spreadsheet rather than a CSV.
  static bool isExcel(String fileName) {
    final String n = fileName.toLowerCase();
    return n.endsWith('.xlsx') || n.endsWith('.xlsm') || n.endsWith('.xls');
  }

  /// Reads a file into rows of plain strings.
  static List<List<String>> read(Uint8List bytes, String fileName) {
    if (isExcel(fileName)) {
      return _readExcel(bytes);
    }
    // Decoded as UTF-8, not as raw code units: fromCharCodes would turn every
    // Urdu character into mojibake and no heading would ever match.
    return _parseCsv(utf8.decode(bytes, allowMalformed: true));
  }

  static List<List<String>> _readExcel(Uint8List bytes) {
    final Excel book = Excel.decodeBytes(bytes);
    final List<List<String>> rows = <List<String>>[];

    // Only the first sheet is read: a participant list lives on one sheet, and
    // silently merging others could import something unintended.
    if (book.tables.isEmpty) {
      return rows;
    }
    final Sheet? sheet = book.tables[book.tables.keys.first];
    if (sheet == null) {
      return rows;
    }

    for (final List<Data?> line in sheet.rows) {
      final List<String> cells = line
          .map((Data? cell) => cell?.value?.toString().trim() ?? '')
          .toList();
      if (cells.any((String c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }
    return rows;
  }

  /// Minimal RFC 4180 reader: copes with quoted fields containing commas and
  /// newlines, which a naive split on ',' would corrupt.
  static List<List<String>> _parseCsv(String rawInput) {
    // Excel's "CSV UTF-8" export begins with a byte-order mark. Left in place
    // it becomes part of the first heading, so nothing would be recognised.
    final String input =
        rawInput.startsWith('﻿') ? rawInput.substring(1) : rawInput;

    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final String c = input[i];

      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
        continue;
      }

      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        row.add(field.toString());
        field.clear();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString());
        field.clear();
        if (row.any((String f) => f.trim().isNotEmpty)) {
          rows.add(row);
        }
        row = <String>[];
      } else {
        field.write(c);
      }
    }

    row.add(field.toString());
    if (row.any((String f) => f.trim().isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }

  /// Maps the header row onto field names. A field with no matching column is
  /// absent from the result, which is how a missing required column is found.
  static Map<String, int> mapColumns(List<String> header) {
    final Map<String, int> columns = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      final String key = normalise(header[i]);
      for (final MapEntry<String, List<String>> entry in _headings.entries) {
        if (columns.containsKey(entry.key)) {
          continue;
        }
        if (entry.value.any((String h) => normalise(h) == key)) {
          columns[entry.key] = i;
        }
      }
    }
    return columns;
  }

  /// A month is accepted when it is blank or looks like one: a machine date,
  /// or any value carrying a four digit year in either digit set. It is stored
  /// exactly as written, because the organisation's own wording is the record.
  static bool isMonthLike(String value) {
    final String v = value.trim();
    if (v.isEmpty) {
      return true;
    }
    if (DateTime.tryParse(v) != null) {
      return true;
    }
    return RegExp(r'[0-9٠-٩۰-۹]{4}').hasMatch(v);
  }

  /// Turns a read file into candidate rows, each carrying why it was refused
  /// when it was. Repeats within the file are caught here; repeats against the
  /// database are caught by the repository.
  static ({List<CandidateRow> rows, bool missingColumns}) toCandidates(
    List<List<String>> table,
  ) {
    if (table.isEmpty) {
      return (rows: <CandidateRow>[], missingColumns: true);
    }

    final Map<String, int> columns = mapColumns(table.first);
    if (!columns.containsKey('registration_number') ||
        !columns.containsKey('full_name')) {
      return (rows: <CandidateRow>[], missingColumns: true);
    }

    String cell(List<String> line, String field) {
      final int? index = columns[field];
      if (index == null || index >= line.length) {
        return '';
      }
      return line[index].trim();
    }

    final List<CandidateRow> out = <CandidateRow>[];
    final Set<String> seen = <String>{};

    for (final List<String> line in table.skip(1)) {
      final String number = cell(line, 'registration_number');
      final String name = cell(line, 'full_name');
      final String start = cell(line, 'course_start_date');
      final String end = cell(line, 'course_completion_date');
      final String period = cell(line, 'course_period');

      CandidateProblem? problem;
      if (number.isEmpty) {
        problem = CandidateProblem.missingNumber;
      } else if (name.isEmpty) {
        problem = CandidateProblem.missingName;
      } else if (!isMonthLike(start) ||
          !isMonthLike(end) ||
          !isMonthLike(period)) {
        problem = CandidateProblem.invalidMonth;
      } else {
        final String key =
            number.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        if (!seen.add(key)) {
          problem = CandidateProblem.duplicateInFile;
        }
      }

      out.add(CandidateRow(
        registrationNumber: number,
        fullName: name,
        courseStartDate: start.isEmpty ? null : start,
        courseCompletionDate: end.isEmpty ? null : end,
        coursePeriod: period.isEmpty ? null : period,
        problem: problem,
      ));
    }

    return (rows: out, missingColumns: false);
  }
}
