/// Formats numbers for the Urdu interface, in Latin digits.
///
/// The interface is Urdu and right-to-left, but its numerals are 0-9. The
/// organisation asked for Latin digits throughout: a رقم التسجیل, a date and a
/// count are all read aloud, copied and checked against paper records, and the
/// Urdu forms (۱۲۳) made that harder rather than easier.
///
/// [convert] folds rather than passes through, so an Urdu digit arriving from
/// stored data is shown in the same form as one the application produced
/// itself. Every count, date, ratio and file size is formatted here or in
/// `UrduDates`, which routes through here — so this is the one place the
/// numeral form is decided.
class UrduNumbers {
  const UrduNumbers._();

  /// Rewrites every Arabic-Indic or extended Arabic-Indic digit in [input] as
  /// its Latin counterpart, and leaves all other characters untouched.
  ///
  /// Latin digits pass through unchanged, so calling this twice is harmless.
  static String convert(String input) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.runes) {
      if (rune >= 0x0660 && rune <= 0x0669) {
        // ٠-٩ — Arabic-Indic.
        buffer.write(rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        // ۰-۹ — the extended forms an Urdu keyboard produces.
        buffer.write(rune - 0x06F0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Formats an integer.
  static String fromInt(int value) => convert(value.toString());

  /// Formats a percentage such as `75` into a percentage label.
  static String percent(int value) => '${convert(value.toString())}%';

  /// Formats a ratio such as 12 of 20.
  static String ratio(int value, int total) =>
      '${convert(value.toString())} / ${convert(total.toString())}';
}
