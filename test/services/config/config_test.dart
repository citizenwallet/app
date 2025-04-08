import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/legacy.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test/test.dart';

const List<Map<String, dynamic>> communityConfigs = [
  {
    "community": {
      "name": "",
      "description": "",
      "url": "",
      "logo": "",
      "alias": "app",
    },
    "scan": {"url": "", "name": ""},
    "indexer": {"url": "", "ipfs_url": "", "key": ""},
    "ipfs": {"url": ""},
    "node": {"url": "", "ws_url": ""},
    "erc4337": {
      "rpc_url": "",
      "entrypoint_address": "",
      "account_factory_address": "",
      "paymaster_rpc_url": "",
      "paymaster_type": ""
    },
    "token": {
      "standard": "",
      "address": "",
      "name": "",
      "symbol": "",
      "decimals": 2
    },
    "profile": {"address": ""}
  },
  {
    "community": {
      "name": "",
      "description": "",
      "url": "",
      "logo": "",
      "alias": "wallet.oak.community",
      "custom_domain": "wallet.oak.community"
    },
    "scan": {"url": "", "name": ""},
    "indexer": {"url": "", "ipfs_url": "", "key": ""},
    "ipfs": {"url": ""},
    "node": {"url": "", "ws_url": ""},
    "erc4337": {
      "rpc_url": "",
      "entrypoint_address": "",
      "account_factory_address": "",
      "paymaster_rpc_url": "",
      "paymaster_type": ""
    },
    "token": {
      "standard": "",
      "address": "",
      "name": "",
      "symbol": "",
      "decimals": 2
    },
    "profile": {"address": ""}
  },
  {
    "community": {
      "name": "",
      "description": "",
      "url": "",
      "logo": "",
      "alias": "usdbc.base",
    },
    "scan": {"url": "", "name": ""},
    "indexer": {"url": "", "ipfs_url": "", "key": ""},
    "ipfs": {"url": ""},
    "node": {"url": "", "ws_url": ""},
    "erc4337": {
      "rpc_url": "",
      "entrypoint_address": "",
      "account_factory_address": "",
      "paymaster_rpc_url": "",
      "paymaster_type": ""
    },
    "token": {
      "standard": "",
      "address": "",
      "name": "",
      "symbol": "",
      "decimals": 2
    },
    "profile": {"address": ""}
  },
  {
    "community": {
      "name": "",
      "description": "",
      "url": "",
      "logo": "",
      "alias": "wallet.regensunite.earth",
      "custom_domain": "wallet.regensunite.earth"
    },
    "scan": {"url": "", "name": ""},
    "indexer": {"url": "", "ipfs_url": "", "key": ""},
    "ipfs": {"url": ""},
    "node": {"url": "", "ws_url": ""},
    "erc4337": {
      "rpc_url": "",
      "entrypoint_address": "",
      "account_factory_address": "",
      "paymaster_rpc_url": "",
      "paymaster_type": ""
    },
    "token": {
      "standard": "",
      "address": "",
      "name": "",
      "symbol": "",
      "decimals": 2
    },
    "profile": {"address": ""}
  }
];

const List<String> expectedWalletUrls = [
  'https://app.citizenwallet.xyz/#/?alias=app',
  'https://app.citizenwallet.xyz/#/?alias=wallet.oak.community',
  'https://app.citizenwallet.xyz/#/?alias=usdbc.base',
  'https://app.citizenwallet.xyz/#/?alias=wallet.regensunite.earth'
];

void main() {
  setUpAll(() async {
    await dotenv.load();

    ConfigService().init(
      dotenv.get('WALLET_CONFIG_URL'),
    );
  });

  group('community', () {
    test('returns a valid wallet url for a given community', () async {
      final deepLinkURL = dotenv.get('ORIGIN_HEADER');

      final List<LegacyConfig> legacyConfigs = communityConfigs
          .map((e) => LegacyConfig.fromJson(e))
          .toList(growable: false);

      for (var i = 0; i < legacyConfigs.length; i++) {
        expect(
          legacyConfigs[i].community.walletUrl(deepLinkURL),
          expectedWalletUrls[i],
        );
      }

      final List<Config> configs = legacyConfigs
          .map((e) => Config.fromLegacy(e))
          .toList(growable: false);

      for (var i = 0; i < configs.length; i++) {
        expect(
          configs[i].community.walletUrl(deepLinkURL),
          expectedWalletUrls[i],
        );
      }
    });
  });
}
