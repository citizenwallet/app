import 'package:flutter/material.dart';

class AmountState with ChangeNotifier {
  List<String> pressedKeys = ['0', '0', '0'];

  void clearInputs() {
    pressedKeys = [];
    notifyListeners();
  }

  void normalKey(String value) {
    if (pressedKeys.length == 3) {
      if (pressedKeys[0] == '0') pressedKeys.removeAt(0);
    }
    pressedKeys.add(value);
    notifyListeners();
  }

  void deleteKey() {
    pressedKeys.removeLast();
    if (pressedKeys.length < 3) {
      pressedKeys.insert(0, '0');
    }
    notifyListeners();
  }
}
