import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _preferences;

  Future init() async {
    _preferences = await SharedPreferences.getInstance();
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

  Future setFirstLaunch(bool firstLaunch) async {
    await _preferences.setBool('firstLaunch', firstLaunch);
  }

  bool get firstLaunch => _preferences.getBool('firstLaunch') ?? true;

  Future setChainId(int chainId) async {
    await _preferences.setInt('chainId', chainId);
  }

  int get chainId =>
      _preferences.getInt('chainId') ??
      int.parse(dotenv.get('DEFAULT_CHAIN_ID'));

  Future setLastWallet(String address) async {
    await _preferences.setString('lastWallet', address);
  }

  String? get lastWallet => _preferences.getString('lastWallet');

  Future setLastWalletLink(String link) async {
    await _preferences.setString('lastWalletLink', link);
  }

  String? get lastWalletLink => _preferences.getString('lastWalletLink');
}
