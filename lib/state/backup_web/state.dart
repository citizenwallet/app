import 'package:flutter/cupertino.dart';

class BackupWebState with ChangeNotifier {
  String shareLink = '';

  void setShareLink(String link) {
    shareLink = link;
    notifyListeners();
  }
}
