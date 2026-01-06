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
  static const String communityConfigListS3FileName = 'communities';

  static const String communityDebugFileName = 'debug';
  static const int version = 5;

  final PreferencesService _pref = PreferencesService();
  late APIService _api;
  late APIService _communityServer;
  bool singleCommunityMode = false;

  List<Config> _configs = [];

  Future<Config> getConfig(String alias, String? location) async {
    return _getConfig(fixLegacyAliases(alias), location);
  }

  Future<Config> getWebConfig(String appLinkSuffix, String? location) async {
    try {
      if (kDebugMode) {
        final localConfig = jsonDecode(
            await rootBundle.loadString('assets/config/v$version/debug.json'));

        _configs = [Config.fromJson(localConfig)];

        return _configs.first;
      }

      if (_configs.isNotEmpty && _configs.length == 1) {
        _communityServer.get(url: '/config/community.json').then((response) {
          final config = Config.fromJson(response);

          _configs = [config];
        }).catchError((e, s) {
          print('Error fetching config: $e');
          print('Stacktrace: $s');
        });

        return _configs.first;
      }

      final response =
          await _communityServer.get(url: '/config/community.json');

      final config = Config.fromJson(response);

      _configs = [config];

      return config;
    } catch (e, s) {
      print('Error fetching config: $e');
      print('Stacktrace: $s');
    }

    String alias = Uri.base.host.endsWith(appLinkSuffix)
        ? Uri.base.host.replaceFirst(appLinkSuffix, '')
        : Uri.base.host;

    alias = alias == 'localhost' || alias == '' ? 'gratitude' : alias;

    return _getConfig(alias, location);
  }

  Future<Config> _getConfig(String alias, String? location) async {
    if (_configs.isNotEmpty) {
      final Config? config = _configs.firstWhereOrNull(
        (element) => element.community.alias == alias,
      );

      if (config != null) {
        // still fetch and update the local cache in the background
        getConfigs(location: config.configLocation).then((value) {
          _configs = value;
        }).catchError((_) {});

        return config;
      }
    }

    // NEW: Try direct fetch first (more efficient)
    try {
      final config = await getConfigByAlias(alias);
      if (config != null) {
        return config;
      }
    } catch (_) {}

    try {
      // fetch the config and await
      _configs = await getConfigs(location: location);
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
  }

  Future<List<Config>> getConfigs({String? location}) async {
    if (kDebugMode) {
      final localConfigs = jsonDecode(await rootBundle.loadString(
          'assets/config/v$version/$communityConfigListFileName.json'));

      final configs =
          (localConfigs as List).map((e) => Config.fromJson(e)).toList();

      return configs;
    }

    if (location != null) {
      // we only need a single file for the web
      final response = await _api.get(url: location);

      return [Config.fromJson(response)];
    }

    final response = await _api.get(url: '/api/communities');

    _pref.setConfigs(response);

    // The API returns an array of wrapper objects with the config nested in the 'json' field
    final configs = (response as List).map((e) {
      final configData = e['json'] as Map<String, dynamic>;
      return Config.fromJson(configData);
    }).toList();

    return configs;
  }

  Future<List<Config>> getLocalConfigs() async {
    try {
      debugPrint(
          '📄 Loading JSON file: assets/config/v$version/$communityConfigListFileName.json');
      final jsonString = await rootBundle.loadString(
          'assets/config/v$version/$communityConfigListFileName.json');

      debugPrint('📄 JSON loaded, size: ${jsonString.length} chars');
      debugPrint('📄 Parsing JSON...');
      final localConfigs = jsonDecode(jsonString);

      debugPrint(
          '📄 JSON parsed, found ${(localConfigs as List).length} items');
      debugPrint('📄 Converting to Config objects...');

      final configs = <Config>[];
      for (var i = 0; i < localConfigs.length; i++) {
        try {
          final config = Config.fromJson(localConfigs[i]);
          configs.add(config);
          if ((i + 1) % 10 == 0 || i == localConfigs.length - 1) {
            debugPrint('📄 Converted ${i + 1}/${localConfigs.length} configs');
          }
        } catch (e) {
          debugPrint('❌ Error converting config $i: $e');
        }
      }

      debugPrint('📄 All configs converted successfully');
      return configs;
    } catch (e, s) {
      debugPrint('ERROR in getLocalConfigs: $e');
      debugPrintStack(stackTrace: s);
      return [];
    }
  }

  Future<Config?> getRemoteConfig(String remoteConfigUrl) async {
    if (kDebugMode && singleCommunityMode) {
      final debugConfig = jsonDecode(
          await rootBundle.loadString('assets/config/v$version/debug.json'));

      return Config.fromJson(debugConfig);
    }

    if (kDebugMode && !singleCommunityMode) {
      return null;
    }

    final remote = APIService(baseURL: remoteConfigUrl);

    try {
      final dynamic response =
          await remote.get(url: '?cachebuster=${generateCacheBusterValue()}');

      if (response == null) {
        debugPrint('Empty response for remote config');
        return null;
      }

      // The API returns a wrapper object with the config nested in the 'json' field
      final configData = response['json'] as Map<String, dynamic>?;
      if (configData == null) {
        debugPrint('No json field in response for remote config');
        return null;
      }

      final config = Config.fromJson(configData);

      return config;
    } catch (e, s) {
      debugPrint('Error fetching remote config: $e');
      debugPrint('Stacktrace: $s');

      return null;
    }
  }

  Future<List<Config>> getCommunitiesFromRemote() async {
    if (kDebugMode) {
      final localConfigs = jsonDecode(await rootBundle.loadString(
          'assets/config/v$version/$communityConfigListFileName.json'));

      final configs =
          (localConfigs as List).map((e) => Config.fromJson(e)).toList();

      return configs;
    }

    final List<dynamic> response = await _api.get(url: '/api/communities');

    // The API returns an array of wrapper objects with the config nested in the 'json' field
    final List<Config> communities = response.map((item) {
      final configData = item['json'] as Map<String, dynamic>;
      return Config.fromJson(configData);
    }).toList();

    return communities;
  }

  Future<Config?> getConfigByAlias(String alias) async {
    if (kDebugMode) {
      final localConfigs = jsonDecode(await rootBundle.loadString(
          'assets/config/v$version/$communityConfigListFileName.json'));

      final configs =
          (localConfigs as List).map((e) => Config.fromJson(e)).toList();
      return configs.firstWhereOrNull((c) => c.community.alias == alias);
    }

    try {
      final response = await _api.get(url: '/api/communities/$alias');
      if (response == null) {
        debugPrint('Empty response for config: $alias');
        return null;
      }
      // The API returns a wrapper object with the config nested in the 'json' field
      final configData = response['json'] as Map<String, dynamic>?;
      if (configData == null) {
        debugPrint('No json field in response for config: $alias');
        return null;
      }
      return Config.fromJson(configData);
    } catch (e, s) {
      debugPrint('Error fetching config for $alias: $e');
      debugPrint('Stacktrace: $s');
      return null;
    }
  }

  Future<bool> isCommunityOnline(String indexerUrl) async {
    final indexer = APIService(baseURL: indexerUrl, netTimeoutSeconds: 20);

    try {
      await indexer.get(url: '/health');
      return true;
    } catch (e, s) {
      debugPrint('indexerUrl: $indexerUrl');
      debugPrint('Error checking if community is online: $e, $indexerUrl');
      debugPrint('Stacktrace: $s, $indexerUrl');

      return false;
    }
  }
}
