import 'package:flutter/services.dart';

class AmountFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final r = RegExp("^\\d+([\\.\\,]\\d{0,2})?\$");

    if (!r.hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}
