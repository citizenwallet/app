import 'dart:convert';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/utils.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:citizenwallet/utils/date.dart';

Future<Legacy4337Bundlers> getLegacy4337Bundlers() async {
  final localFile = jsonDecode(await rootBundle
      .loadString('assets/config/v3/legacy_4337_bundlers.json'));

  return Legacy4337Bundlers.fromJson(localFile);
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  ConfigService._internal();

  static const String communityConfigListFileName =
      kDebugMode ? 'communities.test' : 'communities';
  static const String communityDebugFileName = 'debug';
  static const int version = 3;

  final PreferencesService _pref = PreferencesService();
  late APIService _api;
  late APIService _communityServer;

  List<Config> _configs = [];

  Future<Config> getConfig(String alias) async {
    return _getConfig(fixLegacyAliases(alias));
  }

  Future<Config> getWebConfig(String appLinkSuffix) async {
    try {
      if (_configs.isNotEmpty && _configs.length == 1) {
        _communityServer.get(url: '/config/community.json').then((response) {
          final config = Config.fromJson(response);

          _configs = [config];
        }).catchError((_) {});

        return _configs.first;
      }

      final response =
          await _communityServer.get(url: '/config/community.json');

      final config = Config.fromJson(response);

      _configs = [config];

      return config;
    } catch (_) {}

    String alias = Uri.base.host.endsWith(appLinkSuffix)
        ? Uri.base.host.replaceFirst(appLinkSuffix, '')
        : Uri.base.host;

    alias = alias == 'localhost' || alias == '' ? 'gratitude' : alias;

    return _getConfig(alias);
  }

  Future<Config> _getConfig(String alias) async {
    if (_configs.isNotEmpty) {
      final Config? config = _configs.firstWhereOrNull(
        (element) => element.community.alias == alias,
      );

      if (config != null) {
        // still fetch and update the local cache in the background
        getConfigs(alias: kIsWeb ? alias : null).then((value) {
          _configs = value;
        }).catchError((_) {});

        return config;
      }
    }

    try {
      // fetch the config and await
      _configs = await getConfigs(alias: kIsWeb ? alias : null);
    } catch (_) {}

    return _configs.firstWhere((element) => element.community.alias == alias);
  }

  void initWeb() {
    final scheme = Uri.base.scheme.isNotEmpty ? Uri.base.scheme : 'http';
    final url = kDebugMode || Uri.base.host.contains('localhost')
        ? 'https://config.internal.citizenwallet.xyz'
        : '$scheme://${Uri.base.host}:${Uri.base.port}/wallet-config';

    _api = APIService(baseURL: url);
    _communityServer = APIService(baseURL: '$scheme://${Uri.base.host}');
  }

  void init(String endpoint) {
    _api = APIService(baseURL: endpoint);

    if (kDebugMode) {
      _loadFromLocal();
      return;
    }

    _loadFromCache();
  }

  void _loadFromCache() {
    final cachedConfig = _pref.getConfigs();
    if (cachedConfig != null) {
      try {
        _configs =
            (cachedConfig as List).map((e) => Config.fromJson(e)).toList();

        return;
      } catch (_) {}
    }

    _loadFromLocal();
  }

  void _loadFromLocal() async {
    final localFile = jsonDecode(await rootBundle.loadString(
        'assets/config/v$version/$communityConfigListFileName.json'));

    _configs = (localFile as List).map((e) => Config.fromJson(e)).toList();
  }

  Future<List<Config>> getConfigs({String? alias}) async {
    if (kDebugMode) {
      final localConfigs = jsonDecode(await rootBundle.loadString(
          'assets/config/v$version/$communityConfigListFileName.json'));

      final configs =
          (localConfigs as List).map((e) => Config.fromJson(e)).toList();

      return configs;
    }

    if (alias != null) {
      // we only need a single file for the web
      final response = await _api.get(
          url:
              '/v$version/$alias.json?cachebuster=${generateCacheBusterValue()}');

      return [Config.fromJson(response)];
    }

    final response = await _api.get(
        url:
            '/v$version/$communityConfigListFileName.json?cachebuster=${generateCacheBusterValue()}');

    _pref.setConfigs(response);

    final configs = (response as List).map((e) => Config.fromJson(e)).toList();

    return configs;
  }
}
