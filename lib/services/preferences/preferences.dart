import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  late SharedPreferences _preferences;

  Future init() async {
    _preferences = await SharedPreferences.getInstance();
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
}
