import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
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

const List<String> expectedVoucherUrls = [
  'https://app.citizenwallet.xyz/#/?alias=app&voucher=',
  'https://app.citizenwallet.xyz/#/?alias=wallet.oak.community&voucher=',
  'https://app.citizenwallet.xyz/#/?alias=usdbc.base&voucher=',
  'https://app.citizenwallet.xyz/#/?alias=wallet.regensunite.earth&voucher='
];

void main() {
  setUpAll(() async {
    await dotenv.load();

    ConfigService().init(
      dotenv.get('WALLET_CONFIG_URL'),
    );
  });

  group('vouchers', () {
    test('returns a valid voucher url for a given community', () async {
      final deepLinkURL = dotenv.get('ORIGIN_HEADER');

      final List<Config> configs = communityConfigs
          .map((e) => Config.fromJson(e))
          .toList(growable: false);

      for (var i = 0; i < configs.length; i++) {
        final config = configs[i];

        final walletUrl = config.community.walletUrl(deepLinkURL);

        final voucher = Voucher(
          address: '0x123',
          alias: config.community.alias,
          balance: '0.0',
          creator: '0x123',
          createdAt: DateTime.now(),
          archived: false,
        );

        final voucherLink = voucher.getLink(
          walletUrl,
          config.token.symbol,
          '123',
        );

        expect(
          voucherLink.startsWith(expectedVoucherUrls[i]),
          true,
        );
      }
    });
  });
}
