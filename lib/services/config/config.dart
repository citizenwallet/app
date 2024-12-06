import 'package:citizenwallet/services/config/legacy.dart';
import 'package:collection/collection.dart';

const String defaultPrimary = '#A256FF';

int parseHexColor(String hex) {
  return int.parse('FF${(hex).substring(1)}', radix: 16);
}

class ColorTheme {
  final int primary;

  ColorTheme({
    primary,
  }) : primary = primary ?? parseHexColor(defaultPrimary);

  factory ColorTheme.fromJson(Map<String, dynamic> json) {
    return ColorTheme(
      primary: parseHexColor(json['primary'] ?? defaultPrimary),
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'primary': '#${primary.toRadixString(16).substring(2)}',
    };
  }
}

class ContractLocation {
  final String address;
  final int chainId;

  ContractLocation({
    required this.address,
    required this.chainId,
  });

  factory ContractLocation.fromJson(Map<String, dynamic> json) {
    return ContractLocation(
      address: json['address'],
      chainId: json['chain_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'chain_id': chainId,
    };
  }

  String get fullAddress => '$chainId:$address';
}

class CommunityConfig {
  final String name;
  final String description;
  final String url;
  final String alias;
  final String logo;
  final String? customDomain;
  final bool hidden;
  final ColorTheme theme;
  final ContractLocation profile;
  final ContractLocation primaryToken;
  final ContractLocation primaryAccountFactory;
  final ContractLocation? primaryCardManager;

  CommunityConfig({
    required this.name,
    required this.description,
    required this.url,
    required this.alias,
    required this.logo,
    this.customDomain,
    this.hidden = false,
    required this.theme,
    required this.profile,
    required this.primaryToken,
    required this.primaryAccountFactory,
    this.primaryCardManager,
  });

  factory CommunityConfig.fromJson(Map<String, dynamic> json) {
    final theme = json['theme'] == null
        ? ColorTheme()
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
      profile: ContractLocation.fromJson(json['profile']),
      primaryToken: ContractLocation.fromJson(json['primary_token']),
      primaryAccountFactory:
          ContractLocation.fromJson(json['primary_account_factory']),
        primaryCardManager: json['primary_card_manager'] != null
            ? ContractLocation.fromJson(json['primary_card_manager'])
            : null,
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
      'theme': theme,
      'profile': profile.toJson(),
      'primary_token': primaryToken.toJson(),
      'primary_account_factory': primaryAccountFactory.toJson(),
      if (primaryCardManager != null)
        'primary_card_manager': primaryCardManager!.toJson(),
    };
  }

  // to string
  @override
  String toString() {
    return 'CommunityConfig{name: $name, description: $description, url: $url, alias: $alias}';
  }

  String walletUrl(String deepLinkBaseUrl) =>
      '$deepLinkBaseUrl/#/?alias=$alias';
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
  final int chainId;
  final String entrypointAddress;
  final String? paymasterAddress;
  final String accountFactoryAddress;
  final String paymasterType;
  final int gasExtraPercentage;

  ERC4337Config({
    required this.chainId,
    required this.entrypointAddress,
    this.paymasterAddress,
    required this.accountFactoryAddress,
    required this.paymasterType,
    this.gasExtraPercentage = 13,
  });

  factory ERC4337Config.fromJson(Map<String, dynamic> json) {
    return ERC4337Config(
      chainId: json['chain_id'],
      entrypointAddress: json['entrypoint_address'],
      paymasterAddress: json['paymaster_address'],
      accountFactoryAddress: json['account_factory_address'],
      paymasterType: json['paymaster_type'],
      gasExtraPercentage: json['gas_extra_percentage'] ?? 13,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chain_id': chainId,
      'entrypoint_address': entrypointAddress,
      if (paymasterAddress != null) 'paymaster_address': paymasterAddress,
      'account_factory_address': accountFactoryAddress,
      'paymaster_type': paymasterType,
      'gas_extra_percentage': gasExtraPercentage,
    };
  }

  // to string
  @override
  String toString() {
    return 'ERC4337Config{chainId: $chainId, entrypointAddress: $entrypointAddress, paymasterAddress: $paymasterAddress, accountFactoryAddress: $accountFactoryAddress}';
  }
}

class TokenConfig {
  final String standard;
  final String address;
  final String name;
  final String symbol;
  final int decimals;
  final int chainId;

  TokenConfig({
    required this.standard,
    required this.address,
    required this.name,
    required this.symbol,
    required this.decimals,
    required this.chainId,
  });

  factory TokenConfig.fromJson(Map<String, dynamic> json) {
    return TokenConfig(
      standard: json['standard'],
      address: json['address'],
      name: json['name'],
      symbol: json['symbol'],
      decimals: json['decimals'],
      chainId: json['chain_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standard': standard,
      'address': address,
      'name': name,
      'symbol': symbol,
      'decimals': decimals,
      'chain_id': chainId,
    };
  }

  // to string
  @override
  String toString() {
    return 'TokenConfig{standard: $standard, address: $address , name: $name, symbol: $symbol, decimals: $decimals, chainId: $chainId}';
  }
}

enum PluginLaunchMode {
  webview,
  external;
}

class PluginConfig {
  final String name;
  final String? icon;
  final String url;
  final PluginLaunchMode launchMode;
  final String? action;
  final bool hidden;

  PluginConfig({
    required this.name,
    this.icon,
    required this.url,
    this.launchMode = PluginLaunchMode.external,
    this.action,
    this.hidden = false,
  });

  factory PluginConfig.fromJson(Map<String, dynamic> json) {
    return PluginConfig(
      name: json['name'],
      icon: json['icon'],
      url: json['url'],
      launchMode: json['launch_mode'] == 'webview'
          ? PluginLaunchMode.webview
          : PluginLaunchMode.external,
      action: json['action'],
      hidden: json['hidden'] ?? false,
    );
  }

  // to json
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'url': url,
      'launch_mode': launchMode.name,
      if (action != null) 'action': action,
      'hidden': hidden,
    };
  }

  // to string
  @override
  String toString() {
    return 'PluginConfig{name: $name, icon: $icon, url: $url}';
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

enum CardManagerType {
  classic,
  safe;
}

class CardsConfig extends ContractLocation {
  final String? instanceId;
  final CardManagerType type;

  CardsConfig({
    required super.chainId,
    required super.address,
    this.instanceId,
    this.type = CardManagerType.safe,
  });

  factory CardsConfig.fromJson(Map<String, dynamic> json) {
    return CardsConfig(
        chainId: json['chain_id'],
        address: json['address'],
        type: CardManagerType.values.firstWhere((t) => t.name == json['type']));
  }

  // to json
  @override
  Map<String, dynamic> toJson() {
    return {
      'chain_id': chainId,
      'address': address,
      'type': type.name,
    };
  }

  // to string
  @override
  String toString() {
    return 'CardsConfig{chainId: $chainId, address: $address, type: $type}';
  }
}

class ChainConfig {
  final int id;
  final NodeConfig node;

  ChainConfig({
    required this.id,
    required this.node,
  });

  factory ChainConfig.fromJson(Map<String, dynamic> json) {
    return ChainConfig(
      id: json['id'],
      node: NodeConfig.fromJson(json['node']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'node': node.toJson(),
    };
  }
}

class Config {
  final CommunityConfig community;
  final Map<String, TokenConfig> tokens;
  final ScanConfig scan;
  final Map<String, ERC4337Config> accounts;
  final Map<String, CardsConfig>? cards;
  final Map<String, ChainConfig> chains;
  final IPFSConfig ipfs;
  final List<PluginConfig>? plugins;
  final String configLocation;
  final int version;
  bool online;

  Config({
    required this.community,
    required this.tokens,
    required this.scan,
    required this.accounts,
    required this.cards,
    required this.chains,
    required this.ipfs,
    required this.plugins,
    required this.configLocation,
    this.version = 0,
    this.online = true,
  });

  factory Config.fromLegacy(LegacyConfig legacy) {
    final community = CommunityConfig(
      name: legacy.community.name,
      description: legacy.community.description,
      url: legacy.community.url,
      alias: legacy.community.alias,
      logo: legacy.community.logo,
      customDomain: legacy.community.customDomain,
      hidden: legacy.community.hidden,
      theme: ColorTheme(primary: legacy.community.theme.primary),
      profile: ContractLocation(
        address: legacy.profile.address,
        chainId: legacy.node.chainId,
      ),
      primaryToken: ContractLocation(
        address: legacy.token.address,
        chainId: legacy.node.chainId,
      ),
      primaryAccountFactory: ContractLocation(
        address: legacy.erc4337.accountFactoryAddress,
        chainId: legacy.node.chainId,
      ),
      primaryCardManager: ContractLocation(
        address: legacy.safeCards?.cardManagerAddress ??
            legacy.cards?.cardFactoryAddress ??
            '',
        chainId: legacy.node.chainId,
      ),
    );

    final tokens = {
      '${legacy.node.chainId}:${legacy.token.address}': TokenConfig(
        standard: legacy.token.standard,
        address: legacy.token.address,
        name: legacy.token.name,
        symbol: legacy.token.symbol,
        decimals: legacy.token.decimals,
        chainId: legacy.node.chainId,
      ),
    };

    final accounts = {
      '${legacy.node.chainId}:${legacy.erc4337.accountFactoryAddress}':
          ERC4337Config(
        chainId: legacy.node.chainId,
        entrypointAddress: legacy.erc4337.entrypointAddress,
        paymasterAddress: legacy.erc4337.paymasterAddress,
        accountFactoryAddress: legacy.erc4337.accountFactoryAddress,
        paymasterType: legacy.erc4337.paymasterType,
        gasExtraPercentage: legacy.erc4337.gasExtraPercentage,
      ),
    };

    final cards = legacy.safeCards != null || legacy.cards != null
        ? {
            '${legacy.node.chainId}:${legacy.safeCards?.cardManagerAddress ?? legacy.cards!.cardFactoryAddress}':
                CardsConfig(
              chainId: legacy.node.chainId,
              address: legacy.safeCards?.cardManagerAddress ??
                  legacy.cards!.cardFactoryAddress,
              instanceId: legacy.safeCards?.instanceId,
              type: legacy.safeCards != null
                  ? CardManagerType.safe
                  : CardManagerType.classic,
            ),
          }
        : <String, CardsConfig>{};

    final chains = {
      legacy.node.chainId.toString(): ChainConfig(
        id: legacy.node.chainId,
        node: NodeConfig(
          chainId: legacy.node.chainId,
          url: legacy.node.url,
          wsUrl: legacy.node.wsUrl,
        ),
      ),
    };

    return Config(
      community: community,
      tokens: tokens,
      scan: ScanConfig(name: legacy.scan.name, url: legacy.scan.url),
      accounts: accounts,
      cards: cards,
      chains: chains,
      ipfs: IPFSConfig(url: legacy.ipfs.url),
      plugins: legacy.plugins
          .map((e) => PluginConfig(name: e.name, icon: e.icon, url: e.url))
          .toList(),
      configLocation: legacy.community.customDomain != null
          ? 'https://${legacy.community.customDomain}/config/community.json'
          : 'https://${legacy.community.alias}.citizenwallet.xyz/config/community.json',
      version: 4,
      online: true,
    );
  }

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      community: CommunityConfig.fromJson(json['community']),
      tokens: (json['tokens'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, TokenConfig.fromJson(value))),
      scan: ScanConfig.fromJson(json['scan']),
      accounts: (json['accounts'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, ERC4337Config.fromJson(value))),
      cards: (json['cards'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, CardsConfig.fromJson(value))),
      chains: (json['chains'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, ChainConfig.fromJson(value))),
      ipfs: IPFSConfig.fromJson(json['ipfs']),
      plugins: (json['plugins'] as List?)
          ?.map((e) => PluginConfig.fromJson(e))
          .toList(),
      configLocation: json['config_location'],
      version: json['version'] ?? 0,
      online: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community': community.toJson(),
      'tokens': tokens.map((key, value) => MapEntry(key, value.toJson())),
      'scan': scan.toJson(),
      'accounts': accounts.map((key, value) => MapEntry(key, value.toJson())),
      if (cards != null)
        'cards': cards!.map((key, value) => MapEntry(key, value.toJson())),
      'chains': chains.map((key, value) => MapEntry(key, value.toJson())),
      'ipfs': ipfs.toJson(),
      if (plugins != null) 'plugins': plugins!.map((e) => e.toJson()).toList(),
      'config_location': configLocation,
      'version': version,
    };
  }

  // to string
  @override
  String toString() {
    return 'Config{community: $community, scan: $scan, chains: $chains, ipfs: $ipfs, tokens: $tokens, plugins: $plugins}';
  }

  bool hasCards() {
    return cards?.isNotEmpty ?? false;
  }

  PluginConfig? getTopUpPlugin() {
    return plugins?.firstWhereOrNull((plugin) => plugin.action == 'topup');
  }

  TokenConfig getPrimaryToken() {
    final primaryToken = tokens[community.primaryToken.fullAddress];
    if (primaryToken == null) {
      throw Exception('Primary token not found in config');
    }

    return primaryToken;
  }

  ERC4337Config getPrimaryAccountAbstractionConfig() {
    final primaryAccountAbstraction =
        accounts[community.primaryAccountFactory.fullAddress];

    if (primaryAccountAbstraction == null) {
      throw Exception('Primary Account Abstraction Config not found');
    }

    return primaryAccountAbstraction;
  }

  CardsConfig? getPrimaryCardManager() {
    return cards?[community.primaryCardManager?.fullAddress];
  }

  String getRpcUrl(String chainId) {
    final chain = chains[chainId];

    if (chain == null) {
      throw Exception('Chain not found');
    }

    return '${chain.node.url}/v1/rpc/${getPrimaryAccountAbstractionConfig().paymasterAddress}';
  }
}
