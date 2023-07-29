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

/// Formats a username to only allow alphanumeric characters and hyphens.
class UsernameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final r = RegExp("^[a-zA-Z0-9\\-]*\$");

    if (!r.hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}

/// Formats a name to only allow letters, hyphens, apostrophes, and accented
class NameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) {
      return newValue;
    }

    final r = RegExp("^[a-zA-Z\\-'\u00C0-\u00FF ]*\$");

    if (!r.hasMatch(text)) {
      return oldValue;
    }

    return newValue;
  }
}
