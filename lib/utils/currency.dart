import 'package:intl/intl.dart';

String formatCurrency(double amount, String symbol,
    {int decimalDigits = 2, int factor = 1, bool? isIncoming}) {
  return NumberFormat.currency(
          locale: Intl.systemLocale,
          symbol: isIncoming == null
              ? '$symbol '
              : (isIncoming ? '+ $symbol ' : '- $symbol '),
          decimalDigits: decimalDigits)
      .format(
          (isIncoming == null || isIncoming == true ? amount : -1 * amount) /
              factor);
}

String formatAmount(
  double amount, {
  int decimalDigits = 2,
  int factor = 1,
  bool? isIncoming,
}) {
  return NumberFormat.currency(
          symbol: isIncoming == null ? '' : (isIncoming ? '+ ' : '- '),
          decimalDigits: decimalDigits)
      .format(
          (isIncoming == null || isIncoming == true ? amount : -1 * amount) /
              factor);
}
