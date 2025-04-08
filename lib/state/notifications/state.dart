import 'package:flutter/cupertino.dart';

enum ToastType {
  success,
  error,
}

class NotificationsState with ChangeNotifier {
  bool _push = false;

  bool get push => _push;

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

  void setPush(bool push) {
    _push = push;

    notifyListeners();
  }

  ToastType? _toastDisplay;
  String _toastTitle = '';

  ToastType? get toastDisplay => _toastDisplay;
  String get toastTitle => _toastTitle;

  void toastShow(String title, {ToastType type = ToastType.success}) {
    _toastTitle = title;
    _toastDisplay = type;

    notifyListeners();
  }

  void toastHide() {
    _toastDisplay = null;

    notifyListeners();
  }
}
