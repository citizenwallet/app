import 'package:flutter/cupertino.dart';

class NotificationsState with ChangeNotifier {
  bool _display = false;
  String _title = '';

  bool get display => _display;
  String get title => _title;

  void show(String title) {
    _title = title;
    _display = true;

    notifyListeners();
  }

  void hide() {
    _display = false;

    notifyListeners();
  }
}
