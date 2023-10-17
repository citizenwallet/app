import 'package:flutter/cupertino.dart';

class CardsState with ChangeNotifier {
  bool isAvailable = false;

  void setAvailable(bool value) {
    isAvailable = value;
    notifyListeners();
  }
}
