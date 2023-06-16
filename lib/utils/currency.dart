import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol,
    {int decimalDigits = 2, int factor = 1000, bool? isIncoming}) {
  return '${NumberFormat.currency(symbol: isIncoming == null ? ' ' : (isIncoming ? '+ ' : '- '), decimalDigits: decimalDigits).format(amount / factor)} $symbol';
}

String formatAmount(double amount,
    {int decimalDigits = 2, int factor = 1000, bool? isIncoming}) {
  return NumberFormat.currency(
          symbol: isIncoming == null ? ' ' : (isIncoming ? '+ ' : '- '),
          decimalDigits: decimalDigits)
      .format(amount / factor);
}
