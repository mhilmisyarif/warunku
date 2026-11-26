import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _format = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Formats [value] as Rupiah, e.g. `Rp 12.500`.
  static String format(num value) => _format.format(value);
}

class DateFormatter {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Indonesian short date, e.g. `17 Nov 2026`. Hand-rolled so it needs no
  /// `initializeDateFormatting` call before use.
  static String display(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}

/// Quantity without a pointless ".0": `2`, `1.5`.
String formatQuantity(num value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';
