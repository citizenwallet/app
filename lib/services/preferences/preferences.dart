import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future setDarkMode(bool darkMode) async {
    await _preferences.setBool('darkMode', darkMode);
  }

  bool get darkMode =>
      _preferences.getBool('darkMode') ??
      SchedulerBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;

  // save the first launch property
  Future setFirstLaunch(bool firstLaunch) async {
    await _preferences.setBool('firstLaunch', firstLaunch);
  }

  bool get firstLaunch => _preferences.getBool('firstLaunch') ?? true;

  // save the chain id
  Future setChainId(int chainId) async {
    await _preferences.setInt('chainId', chainId);
  }

  int get chainId =>
      _preferences.getInt('chainId') ??
      int.parse(dotenv.get('DEFAULT_CHAIN_ID'));

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
  Future setConfig(String key, dynamic value) async {
    await _preferences.setString('config_$key', jsonEncode(value));
  }

  dynamic getConfig(String key) {
    final config = _preferences.getString('config_$key');
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

  // save account address for given alias + address
  Future setAccountAddress(
      String alias, String address, String accaddress) async {
    await _preferences.setString(
        'accountAddress_${alias}_$address', accaddress);
  }

  String? getAccountAddress(String alias, String address) {
    return _preferences.getString('accountAddress_${alias}_$address');
  }
}
