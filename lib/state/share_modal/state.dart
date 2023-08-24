import 'package:flutter/cupertino.dart';

class ShareModalState with ChangeNotifier {
  String shareLink = '';

  void setShareLink(String link) {
    shareLink = link;
    notifyListeners();
  }
}
