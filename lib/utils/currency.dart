import 'dart:math';
import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol,
    {int decimalDigits = 2, bool? isIncoming}) {
  return '${NumberFormat.currency(symbol: isIncoming == null ? ' ' : (isIncoming ? '+ ' : '- '), decimalDigits: decimalDigits).format(amount / pow(10, decimalDigits))} $symbol';
}
