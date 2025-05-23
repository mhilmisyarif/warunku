import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern(
    'id_ID',
  );

  static String format(double value) {
    return 'Rp. ${_numberFormat.format(value)}';
  }
}
