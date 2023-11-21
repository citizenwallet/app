import 'dart:convert';

import 'package:citizenwallet/services/api/api.dart';
import 'package:citizenwallet/services/config/utils.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/utils/date.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class CommunityConfig {
  final String name;
  final String description;
  final String url;
  final String alias;
  final String logo;
  final String? customDomain;
  final bool hidden;

  CommunityConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.alias,
    required this.logo,
    this.customDomain,
    this.hidden = false,
  });

  factory CommunityConfig.fromJson(Map<String, dynamic> json) {
    return CommunityConfig(
      name: json['name'],
      description: json['description'],
      url: json['url'],
      alias: json['alias'],
      logo: json['logo'] ?? '',
      customDomain: json['custom_domain'],
      hidden: json['hidden'] ?? false,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'alias': alias,
      'logo': logo,
      'custom_domain': customDomain,
      'hidden': hidden,
    };
  }

  // to string
  @override
  String toString() {
    return 'CommunityConfig{name: $name, description: $description, url: $url, alias: $alias}';
  }

  String walletUrl(String appLinkSuffix) => customDomain != null
      ? 'https://$customDomain'
      : 'https://$alias$appLinkSuffix';
}

class ScanConfig {
  final String url;
  final String name;

  ScanConfig({
    required this.url,
    required this.name,
  });

  factory ScanConfig.fromJson(Map<String, dynamic> json) {
    return ScanConfig(
      url: json['url'],
      name: json['name'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
    };
  }

  // to string
  @override
  String toString() {
    return 'ScanConfig{url: $url, name: $name}';
  }
}

class IndexerConfig {
  final String url;
  final String ipfsUrl;
  final String key;

  IndexerConfig({
    required this.url,
    required this.ipfsUrl,
    required this.key,
  });

  factory IndexerConfig.fromJson(Map<String, dynamic> json) {
    return IndexerConfig(
      url: json['url'],
      ipfsUrl: json['ipfs_url'],
      key: json['key'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'ipfs_url': ipfsUrl,
      'key': key,
    };
  }

  // to string
  @override
  String toString() {
    return 'IndexerConfig{url: $url, ipfsUrl: $ipfsUrl, key: $key}';
  }
}

class IPFSConfig {
  final String url;

  IPFSConfig({
    required this.url,
  });

  factory IPFSConfig.fromJson(Map<String, dynamic> json) {
    return IPFSConfig(
      url: json['url'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
    };
  }

  // to string
  @override
  String toString() {
    return 'IPFSConfig{url: $url}';
  }
}

class NodeConfig {
  final String url;
  final String wsUrl;

  NodeConfig({
    required this.url,
    required this.wsUrl,
  });

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      url: json['url'],
      wsUrl: json['ws_url'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'ws_url': wsUrl,
    };
  }

  // to string
  @override
  String toString() {
    return 'NodeConfig{url: $url, wsUrl: $wsUrl}';
  }
}

class ERC4337Config {
  final String rpcUrl;
  final String entrypointAddress;
  final String accountFactoryAddress;
  final String paymasterRPCUrl;
  final String paymasterType;
  final int gasExtraPercentage;

  ERC4337Config({
    required this.rpcUrl,
    required this.entrypointAddress,
    required this.accountFactoryAddress,
    required this.paymasterRPCUrl,
    required this.paymasterType,
    this.gasExtraPercentage = 13,
  });

  factory ERC4337Config.fromJson(Map<String, dynamic> json) {
    return ERC4337Config(
      rpcUrl: json['rpc_url'],
      entrypointAddress: json['entrypoint_address'],
      accountFactoryAddress: json['account_factory_address'],
      paymasterRPCUrl: json['paymaster_rpc_url'],
      paymasterType: json['paymaster_type'],
      gasExtraPercentage: json['gas_extra_percentage'] ?? 13,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'rpc_url': rpcUrl,
      'entrypoint_address': entrypointAddress,
      'account_factory_address': accountFactoryAddress,
      'paymaster_rpc_url': paymasterRPCUrl,
      'paymaster_type': paymasterType,
      'gas_extra_percentage': gasExtraPercentage,
    };
  }

  // to string
  @override
  String toString() {
    return 'ERC4337Config{rpcUrl: $rpcUrl, entrypointAddress: $entrypointAddress, accountFactoryAddress: $accountFactoryAddress, paymasterRPCUrl: $paymasterRPCUrl, paymasterType: $paymasterType}';
  }
}

class TokenConfig {
  final String standard;
  final String address;
  final String name;
  final String symbol;
  final int decimals;

  TokenConfig({
    required this.standard,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
  });

  factory TokenConfig.fromJson(Map<String, dynamic> json) {
    return TokenConfig(
      standard: json['standard'],
      address: json['address'],
      name: json['name'],
      symbol: json['symbol'],
      decimals: json['decimals'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'standard': standard,
      'address': address,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
    };
  }

  // to string
  @override
  String toString() {
    return 'TokenConfig{standard: $standard, address: $address , name: $name, symbol: $symbol, decimals: $decimals}';
  }
}

class ProfileConfig {
  final String address;

  ProfileConfig({
    required this.address,
  });

  factory ProfileConfig.fromJson(Map<String, dynamic> json) {
    return ProfileConfig(
      address: json['address'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'address': address,
    };
  }

  // to string
  @override
  String toString() {
    return 'ProfileConfig{address: $address}';
  }
}

class Config {
  final CommunityConfig community;
  final ScanConfig scan;
  final IndexerConfig indexer;
  final IPFSConfig ipfs;
  final NodeConfig node;
  final ERC4337Config erc4337;
  final TokenConfig token;
  final ProfileConfig profile;
  final int version;

  Config({
    required this.community,
    required this.scan,
    required this.indexer,
    required this.ipfs,
    required this.node,
    required this.erc4337,
    required this.token,
    required this.profile,
    this.version = 0,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      community: CommunityConfig.fromJson(json['community']),
      scan: ScanConfig.fromJson(json['scan']),
      indexer: IndexerConfig.fromJson(json['indexer']),
      ipfs: IPFSConfig.fromJson(json['ipfs']),
      node: NodeConfig.fromJson(json['node']),
      erc4337: ERC4337Config.fromJson(json['erc4337']),
      token: TokenConfig.fromJson(json['token']),
      profile: ProfileConfig.fromJson(json['profile']),
      version: json['version'] ?? 0,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'community': community,
      'scan': scan,
      'indexer': indexer,
      'ipfs': ipfs,
      'node': node,
      'erc4337': erc4337,
      'token': token,
      'profile': profile,
      'version': version,
    };
  }

  // to string
  @override
  String toString() {
    return 'Config{community: $community, scan: $scan, indexer: $indexer, ipfs: $ipfs, node: $node, erc4337: $erc4337, token: $token, profile: $profile}';
  }
}

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  factory ConfigService() {
    return _instance;
  }

  ConfigService._internal();

  static const int version = 3;
  static const String communityConfigListFileName = 'communities';
  static const String communityDebugFileName = 'debug';

  final PreferencesService _pref = PreferencesService();
  late APIService _api;
  String _alias = '';

  Config? _config;

  Future<Config> get config async {
    if (_config != null && _config!.community.alias == _alias) {
      return _config!;
    }

    _config = await _getConfig();

    return _config!;
  }

  void initWeb(String appLinkSuffix) {
    String alias = Uri.base.host.endsWith(appLinkSuffix)
        ? Uri.base.host.replaceFirst(appLinkSuffix, '')
        : Uri.base.host;

    final url =
        '${Uri.base.scheme}://${Uri.base.host}:${Uri.base.port}/wallet-config';

    _api = APIService(baseURL: url);
    _alias = alias == 'localhost' || alias == '' ? 'app' : alias;
  }

  void init(String endpoint, String alias) {
    _api = APIService(baseURL: endpoint);
    _alias = fixLegacyAliases(alias);
  }

  Future<Config> _getConfig() async {
    if (kDebugMode) {
      final localConfigs = jsonDecode(await rootBundle
          .loadString('assets/config/v$version/$communityDebugFileName.json'));

      final configs =
          (localConfigs as List).map((e) => Config.fromJson(e)).toList();

      return configs.firstWhere((element) => element.community.alias == _alias);
    }

    final cachedConfig = _pref.getConfig(_alias);
    if (cachedConfig != null) {
      final response = await _api
          .get(
              url:
                  '/v$version/$_alias.json?cachebuster=${generateCacheBusterValue()}')
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );

      if (response != null) {
        _pref.setConfig(_alias, response);
        return Config.fromJson(response);
      }

      return Config.fromJson(cachedConfig);
    }

    final response = await _api.get(
        url:
            '/v$version/$_alias.json?cachebuster=${generateCacheBusterValue()}');

    _pref.setConfig(_alias, response);

    return Config.fromJson(response);
  }

  Future<List<Config>> getConfigs() async {
    final response = kDebugMode
        ? jsonDecode(await rootBundle.loadString(
            'assets/config/v$version/$communityConfigListFileName.json'))
        : await _api.get(
            url:
                '/v$version/$communityConfigListFileName.json?cachebuster=${generateCacheBusterValue()}');

    final configs = (response as List).map((e) => Config.fromJson(e)).toList();

    return configs;
  }
}
