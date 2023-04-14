import 'dart:math';
import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol, {int decimalDigits = 2}) {
  print('$amount ${pow(10, decimalDigits)}');
  print(
      'formatted: ${'${NumberFormat.currency(symbol: '', decimalDigits: decimalDigits).format(amount / pow(10, decimalDigits))} $symbol'}');
  return '${NumberFormat.currency(symbol: '', decimalDigits: decimalDigits).format(amount / pow(10, decimalDigits))} $symbol';
}
