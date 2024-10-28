import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Language {
  final String name;
  final String code;

  Language(this.name, this.code);
}

final List<Language> languageOptions = [
  Language('English', 'en'),
  Language('Nederlands', 'nl'),
  Language('Français', 'fr')
];

class AppState with ChangeNotifier {
  String walletPassword = '';
  bool hasCopiedPassword = false;

  // TODO: single mode: ConfigService().singleCommunityMode;
  

  // modifying

  bool walletLoading = false;
  bool walletError = false;

  bool backupDeleteLoading = false;
  bool backupDeleteError = false;

  PackageInfo? packageInfo;

  Language language = languageOptions[0];
  int selectedLanguage = 0;

  bool muted = false;

  AppState() {
    muted = PreferencesService().muted;

    // get the system locale
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    final preferredSystemLocale = locales.isEmpty
        ? const Locale('en').languageCode
        : locales.first.languageCode;

    // get the save language code or fall back to the system locale
    final languageCode =
        PreferencesService().getLanguageCode() ?? preferredSystemLocale;
    int languageCodeIndex =
        languageOptions.indexWhere((element) => element.code == languageCode);
    if (languageCodeIndex < 0) {
      languageCodeIndex = 0;
    }

    language = languageOptions[languageCodeIndex];
    selectedLanguage = languageCodeIndex;
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

  void setMuted(bool muted) {
    this.muted = muted;
    notifyListeners();
  }

  bool appLoading = true;

  void loadApp() {
    appLoading = true;
    notifyListeners();
  }

  void appLoaded() {
    appLoading = false;
    notifyListeners();
  }

  void setLocale(String code) {
    int languageCodeIndex =
        languageOptions.indexWhere((element) => element.code == code);
    if (languageCodeIndex < 0) {
      languageCodeIndex = 0;
    }

    language = languageOptions[languageCodeIndex];
    selectedLanguage = languageCodeIndex;
    notifyListeners();
  }

  void setSelectedLanguage(Language language) {
    int languageCodeIndex =
        languageOptions.indexWhere((element) => element.code == language.code);
    if (languageCodeIndex < 0) {
      languageCodeIndex = 0;
    }

    this.language = language;
    selectedLanguage = languageCodeIndex;
    notifyListeners();
  }
}
