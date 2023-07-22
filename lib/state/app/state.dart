import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppState with ChangeNotifier {
  String walletPassword = '';
  bool hasCopiedPassword = false;

  bool walletLoading = false;
  bool walletError = false;

  bool backupDeleteLoading = false;
  bool backupDeleteError = false;

  PackageInfo? packageInfo;

  CupertinoThemeData get theme {
    return CupertinoThemeData(
      brightness: _darkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _darkMode
          ? ThemeColors.uiBackgroundAlt.darkColor
          : ThemeColors.uiBackgroundAlt.color,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          color:
              _darkMode ? ThemeColors.text.darkColor : ThemeColors.text.color,
          fontSize: 16,
        ),
      ),
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
    onLoad();
  }

  onLoad() async {
    packageInfo = await PackageInfo.fromPlatform();
    notifyListeners();
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

  void deleteBackupLoadingReq() {
    backupDeleteLoading = true;
    backupDeleteError = false;
    notifyListeners();
  }

  void deleteBackupLoadingError() {
    backupDeleteLoading = false;
    backupDeleteError = true;
    notifyListeners();
  }

  void deleteBackupLoadingSuccess() {
    backupDeleteLoading = false;
    backupDeleteError = false;
    notifyListeners();
  }
}
