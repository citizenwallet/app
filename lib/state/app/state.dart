import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:flutter/cupertino.dart';

class AppState with ChangeNotifier {
  String walletPassword = '';
  bool hasCopiedPassword = false;

  bool walletLoading = false;
  bool walletError = false;

  CupertinoThemeData get theme {
    return CupertinoThemeData(
      brightness: _darkMode ? Brightness.dark : Brightness.light,
    );
  }

  bool _darkMode = false;
  bool get darkMode => _darkMode;
  set darkMode(bool darkMode) {
    _darkMode = darkMode;
    notifyListeners();
  }

  bool chainsLoading = false;
  bool chainsError = false;
  List<Chain> chains = [];

  AppState() {
    _darkMode = PreferencesService().darkMode;
  }

  void importLoadingReq() {
    walletLoading = true;
    walletError = false;
    notifyListeners();
  }

  void importLoadingError() {
    walletLoading = false;
    walletError = true;
    notifyListeners();
  }

  void importLoadingSuccess() {
    walletLoading = false;
    walletError = false;
    notifyListeners();
  }

  void importLoadingWebReq() {
    hasCopiedPassword = false;
    walletPassword = '';
    walletLoading = true;
    walletError = false;
    notifyListeners();
  }

  void importLoadingWebError() {
    walletPassword = '';
    walletLoading = false;
    walletError = true;
    notifyListeners();
  }

  void importLoadingWebSuccess(String password) {
    walletPassword = password;

    walletLoading = false;
    walletError = false;
    notifyListeners();
  }

  void hasCopied(bool hasCopied) {
    hasCopiedPassword = hasCopied;
    notifyListeners();
  }

  void loadChains() {
    chainsLoading = true;
    chainsError = false;
    notifyListeners();
  }

  void loadChainsSuccess(List<Chain> chains) {
    this.chains = chains;

    chainsLoading = false;
    chainsError = false;
    notifyListeners();
  }

  void loadChainsError() {
    chainsLoading = false;
    chainsError = true;
    notifyListeners();
  }
}
