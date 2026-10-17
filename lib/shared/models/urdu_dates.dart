import '../../core/utils/urdu_numbers.dart';

/// Formats timestamps as Urdu date and relative-time labels.
///
/// The month names and the words are Urdu; the digits are Latin, which is what
/// the organisation reads them in. Every number here goes through
/// [UrduNumbers], so the numeral form is decided in one place.
class UrduDates {
  const UrduDates._();

  static const List<String> _months = <String>[
    'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون',
    'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];

  /// A full date, for example 3 جنوری 2026.
  static String label(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final DateTime local = value.toLocal();
    final String day = UrduNumbers.fromInt(local.day);
    final String year = UrduNumbers.fromInt(local.year);
    return '$day ${_months[local.month - 1]} $year';
  }

  /// A short relative label such as "دو گھنٹے پہلے".
  static String relative(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final Duration diff = DateTime.now().difference(value.toLocal());

    if (diff.inMinutes < 1) {
      return 'ابھی';
    }
    if (diff.inMinutes < 60) {
      return '${UrduNumbers.fromInt(diff.inMinutes)} منٹ پہلے';
    }
    if (diff.inHours < 24) {
      return '${UrduNumbers.fromInt(diff.inHours)} گھنٹے پہلے';
    }
    if (diff.inDays == 1) {
      return 'کل';
    }
    if (diff.inDays < 30) {
      return '${UrduNumbers.fromInt(diff.inDays)} دن پہلے';
    }
    return label(value);
  }

  /// A deadline label such as "5 دن باقی" or "تاخیر: 3 دن".
  static String due(DateTime? value) {
    if (value == null) {
      return '—';
    }
    final Duration remaining = value.toLocal().difference(DateTime.now());
    if (remaining.isNegative) {
      final int late = remaining.abs().inDays;
      return late == 0
          ? 'آج آخری تاریخ تھی'
          : 'تاخیر: ${UrduNumbers.fromInt(late)} دن';
    }
    final int days = remaining.inDays;
    if (days == 0) {
      return 'آج آخری تاریخ ہے';
    }
    return 'آخری تاریخ: ${UrduNumbers.fromInt(days)} دن باقی';
  }

  /// Formats a byte count as an Urdu file size.
  static String fileSize(int? bytes) {
    if (bytes == null || bytes <= 0) {
      return '—';
    }
    if (bytes < 1024) {
      return '${UrduNumbers.fromInt(bytes)} بائٹ';
    }
    if (bytes < 1024 * 1024) {
      return '${UrduNumbers.fromInt((bytes / 1024).round())} کلو بائٹ';
    }
    final double mb = bytes / (1024 * 1024);
    return '${UrduNumbers.convert(mb.toStringAsFixed(1))} میگا بائٹ';
  }
}
