import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _preferences;

  Future init(SharedPreferences pref) async {
    _preferences = pref;
  }

  Future clear() async {
    await _preferences.clear();
  }

  // save the muted preference for audio service
  Future setMuted(bool muted) async {
    await _preferences.setBool('muted', muted);
  }

  bool get muted => _preferences.getBool('muted') ?? false;

  Future setDarkMode(bool darkMode) async {
    await _preferences.setBool('darkMode', darkMode);
  }

  // save the push notifications preference
  Future setPushNotifications(String account, bool pushNotifications) async {
    await _preferences.setBool('pushNotifications_$account', pushNotifications);
  }

  bool pushNotifications(String account) =>
      _preferences.getBool('pushNotifications_$account') ?? false;

  // bool get darkMode =>
  //     _preferences.getBool('darkMode') ??
  //     SchedulerBinding.instance.platformDispatcher.platformBrightness ==
  //         Brightness.dark;
  bool get darkMode => false;

  // save the first launch property
  Future setFirstLaunch(bool firstLaunch) async {
    await _preferences.setBool('firstLaunch', firstLaunch);
  }

  bool get firstLaunch => _preferences.getBool('firstLaunch') ?? true;

  // save the chain id
  Future setChainId(int chainId) async {
    await _preferences.setInt('chainId', chainId);
  }

  int get chainId => _preferences.getInt('chainId') ?? 1;

  // save chain id for a given alias
  Future setChainIdForAlias(String alias, String chainId) async {
    await _preferences.setString('chainId_$alias', chainId);
  }

  String? getChainIdForAlias(String alias) {
    return _preferences.getString('chainId_$alias');
  }

  // save the last wallet that was opened
  Future setLastWallet(String address) async {
    await _preferences.setString('lastWallet', address);
  }

  String? get lastWallet => _preferences.getString('lastWallet');

  // save the last alias that was opened
  Future setLastAlias(String alias) async {
    await _preferences.setString('lastAlias', alias);
  }

  String? get lastAlias => _preferences.getString('lastAlias');

  // save the last account factory address that was opened
  Future setLastAccountFactoryAddress(String accountFactoryAddress) async {
    await _preferences.setString('lastAccountFactoryAddress', accountFactoryAddress);
  }

  String? get lastAccountFactoryAddress => _preferences.getString('lastAccountFactoryAddress');

  // save the last link that was opened on web
  Future setLastWalletLink(String link) async {
    await _preferences.setString('lastWalletLink', link);
  }

  String? get lastWalletLink => _preferences.getString('lastWalletLink');

  // save the last block number loaded for a given rpc url
  Future setLastBlockNumber(String rpcUrl, int blockNumber) async {
    await _preferences.setInt('lastBlockNumber$rpcUrl', blockNumber);
  }

  int? getLastBlockNumber(String rpcUrl) =>
      _preferences.getInt('lastBlockNumber$rpcUrl');

  bool get androidBackupIsConfigured =>
      _preferences.getBool('androidBackupIsConfigured') ?? false;

  Future setAndroidBackupIsConfigured(bool configured) async {
    await _preferences.setBool('androidBackupIsConfigured', configured);
  }

  // saved configs
  Future setConfigs(dynamic value) async {
    await _preferences.setString('configs', jsonEncode(value));
  }

  dynamic getConfigs() {
    final config = _preferences.getString('configs');
    if (config == null) {
      return null;
    }

    return jsonDecode(config);
  }

  // saved balance
  Future setBalance(String key, String value) async {
    await _preferences.setString('balance_$key', value);
  }

  String? getBalance(String key) {
    return _preferences.getString('balance_$key');
  }

  // save account address for given key
  Future setAccountAddress(String key, String accaddress) async {
    await _preferences.setString('accountAddress_$key', accaddress);
  }

  String? getAccountAddress(String key) {
    return _preferences.getString('accountAddress_$key');
  }

  // last backup time
  Future setLastBackupTime(String value) async {
    await _preferences.setString('lastBackupTime', value);
  }

  String? getLastBackupTime() {
    return _preferences.getString('lastBackupTime');
  }

  // last backup name
  Future setLastBackupName(String value) async {
    await _preferences.setString('lastBackupName', value);
  }

  String? getLastBackupName() {
    return _preferences.getString('lastBackupName');
  }

  Future setLanguageCode(String value) async {
    await _preferences.setString('languageCode', value);
  }

  String? getLanguageCode() {
    return _preferences.getString('languageCode');
  }

  Future setMigrationModalShown(bool shown) async {
    await _preferences.setBool('migrationModalShown', shown);
  }

  bool get migrationModalShown =>
      _preferences.getBool('migrationModalShown') ?? false;

  Future setMigrationModalDismissalCount(int count) async {
    await _preferences.setInt('migrationModalDismissalCount', count);
  }

  int get migrationModalDismissalCount =>
      _preferences.getInt('migrationModalDismissalCount') ?? 0;

  Future incrementMigrationModalDismissalCount() async {
    final currentCount = migrationModalDismissalCount;
    await setMigrationModalDismissalCount(currentCount + 1);
  }

  Future resetMigrationModalDismissalCount() async {
    await setMigrationModalDismissalCount(0);
  }
}
