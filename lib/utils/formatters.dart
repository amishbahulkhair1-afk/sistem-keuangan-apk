import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatCurrency(num? amount) {
    if (amount == null) return 'Rp 0';
    try {
      return _currencyFormat.format(amount);
    } catch (_) {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      try {
        return DateFormat('d MMM yyyy').format(date);
      } catch (_) {
        return '${date.day}-${date.month}-${date.year}';
      }
    }
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '-';
    try {
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      return '$d/$m/${date.year}';
    }
  }
}
