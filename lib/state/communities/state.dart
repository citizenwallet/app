import 'package:citizenwallet/services/config/config.dart';
import 'package:flutter/cupertino.dart';

class CommunitiesState with ChangeNotifier {
  List<Config> communities = [];

  bool loading = false;
  bool error = false;

  void fetchCommunitiesRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void fetchCommunitiesSuccess(List<Config> communities) {
    this.communities = [...communities];
    loading = false;
    error = false;
    notifyListeners();
  }

  void fetchCommunitiesFailure() {
    loading = false;
    error = true;
    notifyListeners();
  }
}
