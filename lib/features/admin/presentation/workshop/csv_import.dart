/// Minimal RFC 4180 style CSV reader.
///
/// Written by hand rather than pulling in a package: the import needs to cope
/// with quoted fields containing commas and newlines, which a naive split on
/// ',' would corrupt, but nothing beyond that.
class CsvImport {
  const CsvImport._();

  /// The columns the importer understands. Anything else in the file is
  /// ignored rather than rejected, so an export carrying extra columns still
  /// imports cleanly.
  static const List<String> knownColumns = <String>[
    'registration_number',
    'full_name',
    'father_name',
    'gender',
    'phone',
    'workshop_name',
    'batch',
    'workshop_date',
  ];

  /// Splits raw CSV text into rows of fields.
  static List<List<String>> parse(String input) {
    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final String c = input[i];

      if (inQuotes) {
        if (c == '"') {
          // A doubled quote inside a quoted field is a literal quote.
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
        // Treat CRLF as one break rather than an empty row.
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

  /// Turns CSV text into rows ready for insertion, keeping only records that
  /// have the two fields the register cannot do without.
  static ({List<Map<String, dynamic>> rows, int invalid}) toParticipants(
    String csv,
  ) {
    final List<List<String>> table = parse(csv);
    if (table.isEmpty) {
      return (rows: <Map<String, dynamic>>[], invalid: 0);
    }

    final List<String> header = table.first
        .map((String h) => h.trim().toLowerCase().replaceAll(' ', '_'))
        .toList();

    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    int invalid = 0;

    for (final List<String> line in table.skip(1)) {
      final Map<String, String> raw = <String, String>{};
      for (int i = 0; i < header.length && i < line.length; i++) {
        raw[header[i]] = line[i].trim();
      }

      final String number = raw['registration_number'] ?? '';
      final String name = raw['full_name'] ?? '';
      if (number.isEmpty || name.isEmpty) {
        invalid++;
        continue;
      }

      out.add(<String, dynamic>{
        'registration_number': number,
        'full_name': name,
        'father_name': _orNull(raw['father_name']),
        'gender': _gender(raw['gender']),
        'phone': _orNull(raw['phone']),
        'workshop_name': _orNull(raw['workshop_name']),
        'batch': _orNull(raw['batch']),
        'workshop_date': _date(raw['workshop_date']),
        // A row in the register means the workshop was attended. Eligibility
        // is granted by default and withdrawn by an administrator.
        'completed': true,
        'eligible': true,
      });
    }
    return (rows: out, invalid: invalid);
  }

  static String? _orNull(String? v) => (v == null || v.isEmpty) ? null : v;

  /// Accepts the spellings a spreadsheet is likely to contain.
  static String? _gender(String? v) {
    final String s = (v ?? '').trim().toLowerCase();
    if (s == 'male' || s == 'm' || s == 'فاضل' || s == 'مرد') {
      return 'male';
    }
    if (s == 'female' || s == 'f' || s == 'فاضلہ' || s == 'خاتون') {
      return 'female';
    }
    return null;
  }

  static String? _date(String? v) {
    if (v == null || v.isEmpty) {
      return null;
    }
    final DateTime? parsed = DateTime.tryParse(v);
    return parsed?.toIso8601String().substring(0, 10);
  }
}
