import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol) {
  return '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)} $symbol';
}
