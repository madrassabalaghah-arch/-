/// Converts Western Arabic digits into the Urdu (Eastern Arabic) digits used
/// throughout the interface.
///
/// The application is Urdu-first, so counts, statistics and dates are shown in
/// Urdu numerals rather than Latin numerals.
class UrduNumbers {
  const UrduNumbers._();

  static const List<String> _digits = <String>[
    '\u06F0',
    '\u06F1',
    '\u06F2',
    '\u06F3',
    '\u06F4',
    '\u06F5',
    '\u06F6',
    '\u06F7',
    '\u06F8',
    '\u06F9',
  ];

  /// Converts every Latin digit inside [input] to its Urdu counterpart and
  /// leaves all other characters untouched.
  static String convert(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int unit in input.codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        buffer.write(_digits[unit - 0x30]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }

  /// Formats an integer using Urdu digits.
  static String fromInt(int value) => convert(value.toString());

  /// Formats a percentage such as `75` into an Urdu percentage label.
  static String percent(int value) => '${convert(value.toString())}%';

  /// Formats a ratio such as 12 of 20.
  static String ratio(int value, int total) =>
      '${convert(value.toString())} / ${convert(total.toString())}';
}
