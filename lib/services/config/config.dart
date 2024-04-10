import 'package:citizenwallet/theme/colors.dart';

class CommunityConfig {
  final String name;
  final String description;
  final String url;
  final String alias;
  final String logo;
  final String? customDomain;
  final bool hidden;
  final ColorTheme theme;

  CommunityConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.alias,
    required this.logo,
    this.customDomain,
    this.hidden = false,
    required this.theme,
  });

  factory CommunityConfig.fromJson(Map<String, dynamic> json) {
    final theme = json['theme'] == null
        ? ColorTheme(primary: ThemeColors.originalSurfacePrimary)
        : ColorTheme.fromJson(json['theme']);

    return CommunityConfig(
      name: json['name'],
      description: json['description'],
      url: json['url'],
      alias: json['alias'],
      logo: json['logo'] ?? '',
      customDomain: json['custom_domain'],
      hidden: json['hidden'] ?? false,
      theme: theme,
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
  final int chainId;
  final String url;
  final String wsUrl;

  NodeConfig({
    required this.chainId,
    required this.url,
    required this.wsUrl,
  });

  factory NodeConfig.fromJson(Map<String, dynamic> json) {
    return NodeConfig(
      chainId: json['chain_id'] ?? 1,
      url: json['url'],
      wsUrl: json['ws_url'],
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'chain_id': chainId,
      'url': url,
      'ws_url': wsUrl,
    };
  }

  // to string
  @override
  String toString() {
    return 'NodeConfig{chainId: $chainId url: $url, wsUrl: $wsUrl}';
  }
}

class ERC4337Config {
  final String rpcUrl;
  final String? paymasterAddress;
  final String entrypointAddress;
  final String accountFactoryAddress;
  final String paymasterRPCUrl;
  final String paymasterType;
  final int gasExtraPercentage;

  ERC4337Config({
    required this.rpcUrl,
    this.paymasterAddress,
    required this.entrypointAddress,
    required this.accountFactoryAddress,
    required this.paymasterRPCUrl,
    required this.paymasterType,
    this.gasExtraPercentage = 13,
  });

  factory ERC4337Config.fromJson(Map<String, dynamic> json) {
    return ERC4337Config(
      rpcUrl: json['rpc_url'],
      paymasterAddress: json['paymaster_address'],
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
      if (paymasterAddress != null) 'paymaster_address': paymasterAddress,
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
    return 'ERC4337Config{rpcUrl: $rpcUrl, paymasterAddress: $paymasterAddress, entrypointAddress: $entrypointAddress, accountFactoryAddress: $accountFactoryAddress, paymasterRPCUrl: $paymasterRPCUrl, paymasterType: $paymasterType}';
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

enum PluginLaunchMode {
  webview,
  external;
}

class PluginConfig {
  final String name;
  final String icon;
  final String url;
  final PluginLaunchMode launchMode;

  PluginConfig({
    required this.name,
    required this.icon,
    required this.url,
    this.launchMode = PluginLaunchMode.external,
  });

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'],
      icon: json['icon'],
      url: json['url'],
      launchMode: json['launch_mode'] == 'webview'
          ? PluginLaunchMode.webview
          : PluginLaunchMode.external,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'url': url,
      'launch_mode': launchMode.name,
    };
  }

  // to string
  @override
  String toString() {
    return 'IndexerConfig{name: $name, icon: $icon, url: $url}';
  }
}

class Legacy4337Bundlers {
  final ERC4337Config polygon;
  final ERC4337Config base;
  final ERC4337Config celo;

  Legacy4337Bundlers({
    required this.polygon,
    required this.base,
    required this.celo,
  });

  factory Legacy4337Bundlers.fromJson(Map<String, dynamic> json) {
    return Legacy4337Bundlers(
      polygon: ERC4337Config.fromJson(json['137']),
      base: ERC4337Config.fromJson(json['8453']),
      celo: ERC4337Config.fromJson(json['42220']),
    );
  }

  ERC4337Config get(String chainId) {
    if (chainId == '137') {
      return polygon;
    }

    return base;
  }

  ERC4337Config? getFromAlias(String alias) {
    if (alias.contains('celo')) {
      return null;
    }

    return switch (alias) {
      'usdc.base' => base,
      'wallet.oak.community' => base,
      'ceur.celo' => celo,
      _ => polygon
    };
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
  final List<PluginConfig> plugins;
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
    required this.plugins,
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
      plugins: json['plugins'] != null
          ? (json['plugins'] as List)
              .map((e) => PluginConfig.fromJson(e))
              .toList()
          : [],
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
      'plugins': plugins,
      'version': version,
    };
  }

  // to string
  @override
  String toString() {
    return 'Config{community: $community, scan: $scan, indexer: $indexer, ipfs: $ipfs, node: $node, erc4337: $erc4337, token: $token, profile: $profile}';
  }
}
