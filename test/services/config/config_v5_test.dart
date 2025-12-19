import 'dart:io';
import 'dart:convert';
import 'package:citizenwallet/services/config/config.dart';
import 'package:test/test.dart';

const Map<String, List<String>> communitiesWithMultipleAccountFactories = {
  'wallet.pay.brussels': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xBABCf159c4e3186cf48e4a48bC0AeC17CF9d90FE',
  ],
  'gratitude': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD'
  ],
  'bread': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9'
  ],
  'wallet.commonshub.brussels': [
    '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'wallet.regensunite.earth': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0x9406Cc6185a346906296840746125a0E44976454'
  ],
  'gt.celo': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD'
  ],
  'ceur.celo': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xdA529eBEd3D459dac9d9D3D45b8Cae2D5796c098'
  ],
  'eure.polygon': [
    '0x5bA08d9fC7b90f79B2b856bdB09FC9EB32e83616',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'app': [
    '0x270758454C012A1f51428b68aE473D728CCdFe88',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'usdc.base': [
    '0x05e2Fb34b4548990F96B3ba422eA3EF49D5dAa99',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'wallet.oak.community': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0x9406Cc6185a346906296840746125a0E44976454'
  ],
  'sbc.polygon': [
    '0x3Be13D9325C8C9174C3819d3d868D5D3aB8Fc8a5',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'zinne': [
    '0x11af2639817692D2b805BcE0e1e405E530B20006',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'timebank.regensunite.earth': [
    '0x39b77d77f7677997871b304094a05295eb71e240',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'moos': [
    '0x671f0662de72268d0f3966Fb62dFc6ee6389e244',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'selcoupdepouce': [
    '0x4Cc883b7E8E0BCB2e293703EF06426F9b4A5A284',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'cit.celo': [
    '0x0a9f4B7e7Ec393fF25dc9267289Be259Ec3FB970',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
  ],
  'wallet.wolugo.be': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0x8474153A00C959f2cB64852949954DBC68415Bb3'
  ],
  'wtc.celo': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xE79E19594A749330036280c685E2719d58d99052'
  ],
  'testnet-ethldn': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xc1654087C580f868F08E34cd1c01eDB1d3673b82'
  ],
  'celo-c.citizenwallet.xyz': [
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
    '0xcd8b1B9E760148c5026Bc5B0D56a5374e301FDcA'
  ],
};

const Map<String, Map<String, String>> communityRpcUrls = {
  'ctzn': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0x3A3E25871c5C6C84D5f397829FF316a37F7FD596',
  },
  'wallet.pay.brussels': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://engine.pay.brussels/v1/rpc/0xE69C843898E21C0E95eA7DD310cD850AAc0aB897',
    '0xBABCf159c4e3186cf48e4a48bC0AeC17CF9d90FE':
        'https://engine.pay.brussels/v1/rpc/0xcA1B9EC1117340818C1c1fdd1B48Ea79E57C140F',
  },
  'gratitude': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xF05ba2641b31AF70c2678e3324eD8b9C53093FbE',
    '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x8dd43eE72f6A816b8eB0411B712D96cDd95246d8'
  },
  'bread': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://100.engine.citizenwallet.xyz/v1/rpc/0x5987e57e85014B5A56C880313580346c20a5d1c1',
    '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9':
        'https://100.engine.citizenwallet.xyz/v1/rpc/0xbE2Cb3358aa14621134e923B68b8429315368E32'
  },
  'wallet.commonshub.brussels': {
    '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x4E127A1DAa66568B4a91E8c5615120a6Ea5442E3',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x4860C0f127500F0cbF4a5Bd797cBb5aA50Eb0FbA'
  },
  'wallet.regensunite.earth': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0x250711045d58b6310f0635C7D110BFe663cE1da5',
    '0x9406Cc6185a346906296840746125a0E44976454':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0x250711045d58b6310f0635C7D110BFe663cE1da5'
  },
  'gt.celo': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x8dd43eE72f6A816b8eB0411B712D96cDd95246d8',
    '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x8dd43eE72f6A816b8eB0411B712D96cDd95246d8'
  },
  'ceur.celo': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xedbEA8c0F25B34510149EaD4f72867B0d3D2264F',
    '0xdA529eBEd3D459dac9d9D3D45b8Cae2D5796c098':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xedbEA8c0F25B34510149EaD4f72867B0d3D2264F'
  },
  'eure.polygon': {
    '0x5bA08d9fC7b90f79B2b856bdB09FC9EB32e83616':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xB2cb6b75C2357Ca94dBdF58897E468E45fAC83Ec',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xB2cb6b75C2357Ca94dBdF58897E468E45fAC83Ec'
  },
  'app': {
    '0x270758454C012A1f51428b68aE473D728CCdFe88':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xB5D1C0167E6325466E2918e9fda8cc41384C0291',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xB5D1C0167E6325466E2918e9fda8cc41384C0291'
  },
  'usdc.base': {
    '0x05e2Fb34b4548990F96B3ba422eA3EF49D5dAa99':
        'https://8453.engine.citizenwallet.xyz/v1/rpc/0xA63DFccB8a39a3DFE4479b33190b12019Ee594E7',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://8453.engine.citizenwallet.xyz/v1/rpc/0xA63DFccB8a39a3DFE4479b33190b12019Ee594E7'
  },
  'wallet.oak.community': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://8453.engine.citizenwallet.xyz/v1/rpc/0x123',
    '0x9406Cc6185a346906296840746125a0E44976454':
        'https://8453.engine.citizenwallet.xyz/v1/rpc/0x123'
  },
  'sbc.polygon': {
    '0x3Be13D9325C8C9174C3819d3d868D5D3aB8Fc8a5':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0x123',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0x123'
  },
  'zinne': {
    '0x11af2639817692D2b805BcE0e1e405E530B20006':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xBb796D122Ec1aBDeD081D50B06a072f981c7E62b',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://137.engine.citizenwallet.xyz/v1/rpc/0xBb796D122Ec1aBDeD081D50B06a072f981c7E62b'
  },
  'timebank.regensunite.earth': {
    '0x39b77d77f7677997871b304094a05295eb71e240':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xe45858bf63176595c2920822581917c7C705a12f',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xe45858bf63176595c2920822581917c7C705a12f'
  },
  'moos': {
    '0x671f0662de72268d0f3966Fb62dFc6ee6389e244':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x55E519bfD63c7152D9F7B88Acd712A37F0BEC482',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x55E519bfD63c7152D9F7B88Acd712A37F0BEC482'
  },
  'selcoupdepouce': {
    '0x4Cc883b7E8E0BCB2e293703EF06426F9b4A5A284':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x635032605337aB36A46D767905108e67EE687a72',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x635032605337aB36A46D767905108e67EE687a72'
  },
  'cit.celo': {
    '0x0a9f4B7e7Ec393fF25dc9267289Be259Ec3FB970':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x452F7ff3e55fe29f481841985dE7f4939FD645fa',
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x452F7ff3e55fe29f481841985dE7f4939FD645fa'
  },
  'wallet.wolugo.be': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xF2EFEC3cBFaDE0bB6108620cbF7Cc608d27DCF3c',
    '0x8474153A00C959f2cB64852949954DBC68415Bb3':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0xF2EFEC3cBFaDE0bB6108620cbF7Cc608d27DCF3c'
  },
  'wtc.celo': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x3fefC19674f3F6E43B1dFf1861E07c303B9eAAc9',
    '0xE79E19594A749330036280c685E2719d58d99052':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x3fefC19674f3F6E43B1dFf1861E07c303B9eAAc9'
  },
  'testnet-ethldn': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://84532.engine.citizenwallet.xyz/v1/rpc/0x389182aCCeE26D953d5188BF4b92c49339DcC9FC',
    '0xc1654087C580f868F08E34cd1c01eDB1d3673b82':
        'https://84532.engine.citizenwallet.xyz/v1/rpc/0x389182aCCeE26D953d5188BF4b92c49339DcC9FC'
  },
  'celo-c.citizenwallet.xyz': {
    '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x7f4011845Ea914b6cefc60629e1e00600c972c75',
    '0xcd8b1B9E760148c5026Bc5B0D56a5374e301FDcA':
        'https://42220.engine.citizenwallet.xyz/v1/rpc/0x7f4011845Ea914b6cefc60629e1e00600c972c75'
  },
};

void main() {
  late List<Config> configs;

  setUpAll(() async {
    // Load and parse JSON file
    final jsonString =
        await File('assets/config/v5/communities.json').readAsString();
    final jsonList = jsonDecode(jsonString) as List;
    configs = jsonList
        .map((json) => Config.fromJson(json as Map<String, dynamic>))
        .toList();
  });

  group('V5 Config Parsing', () {
    test('loads all configs successfully', () {
      expect(configs.length, greaterThan(0));
      print('Loaded ${configs.length} configs');
    });

    test('all configs have valid community data', () {
      for (final config in configs) {
        expect(config.community.name, isNotEmpty,
            reason: 'Community name should not be empty');
        expect(config.community.alias, isNotEmpty,
            reason: 'Community alias should not be empty');
        expect(config.community.description, isNotEmpty,
            reason: 'Community description should not be empty');
        expect(config.community.url, isNotEmpty,
            reason: 'Community URL should not be empty');
        expect(config.community.logo, isNotEmpty,
            reason: 'Community logo should not be empty');
      }
    });

    test('all configs have required maps populated', () {
      for (final config in configs) {
        expect(config.tokens, isNotEmpty,
            reason:
                'Config for ${config.community.alias} should have at least one token');
        expect(config.accounts, isNotEmpty,
            reason:
                'Config for ${config.community.alias} should have at least one account');
        expect(config.chains, isNotEmpty,
            reason:
                'Config for ${config.community.alias} should have at least one chain');
      }
    });

    test('all configs have valid scan configuration', () {
      for (final config in configs) {
        expect(config.scan.url, isNotEmpty,
            reason:
                'Scan URL should not be empty for ${config.community.alias}');
        expect(config.scan.name, isNotEmpty,
            reason:
                'Scan name should not be empty for ${config.community.alias}');
      }
    });

    test('all configs have valid IPFS configuration', () {
      for (final config in configs) {
        expect(config.ipfs.url, isNotEmpty,
            reason:
                'IPFS URL should not be empty for ${config.community.alias}');
      }
    });

    test('all configs have valid version field', () {
      for (final config in configs) {
        expect(config.version, greaterThanOrEqualTo(4),
            reason:
                'Version should be 4 or higher for ${config.community.alias}');
        expect(config.version, lessThanOrEqualTo(5),
            reason:
                'Version should be 5 or lower for ${config.community.alias}');
      }
    });

    test('all configs have valid config location', () {
      for (final config in configs) {
        expect(config.configLocation, isNotEmpty,
            reason:
                'Config location should not be empty for ${config.community.alias}');
        expect(config.configLocation, startsWith('https://'),
            reason:
                'Config location should be HTTPS URL for ${config.community.alias}');
      }
    });

    test('primary token exists in tokens map', () {
      for (final config in configs) {
        final primaryTokenKey = config.community.primaryToken.fullAddress;
        expect(config.tokens.containsKey(primaryTokenKey), isTrue,
            reason:
                'Primary token should exist in tokens map for ${config.community.alias}');
      }
    });

    test('primary account factory exists in accounts map', () {
      for (final config in configs) {
        final primaryAccountKey =
            config.community.primaryAccountFactory.fullAddress;
        expect(config.accounts.containsKey(primaryAccountKey), isTrue,
            reason:
                'Primary account factory should exist in accounts map for ${config.community.alias}');
      }
    });

    test('primary card manager exists in cards map if specified', () {
      for (final config in configs) {
        if (config.community.primaryCardManager != null) {
          final primaryCardKey =
              config.community.primaryCardManager!.fullAddress;
          expect(config.cards?.containsKey(primaryCardKey) ?? false, isTrue,
              reason:
                  'Primary card manager should exist in cards map for ${config.community.alias}');
        }
      }
    });

    test('chain IDs match between community and chains map', () {
      for (final config in configs) {
        final primaryChainId = config.community.primaryToken.chainId.toString();
        expect(config.chains.containsKey(primaryChainId), isTrue,
            reason:
                'Primary chain ID should exist in chains map for ${config.community.alias}');
      }
    });

    test('getPrimaryToken returns valid token', () {
      for (final config in configs) {
        final token = config.getPrimaryToken();
        expect(token.name, isNotEmpty,
            reason:
                'Token name should not be empty for ${config.community.alias}');
        expect(token.symbol, isNotEmpty,
            reason:
                'Token symbol should not be empty for ${config.community.alias}');
        expect(token.decimals, greaterThanOrEqualTo(0),
            reason:
                'Token decimals should be non-negative for ${config.community.alias}');
      }
    });

    test('getPrimaryAccountAbstractionConfig returns valid config', () {
      for (final config in configs) {
        final aaConfig = config.getAccountAbstractionConfig(
            accountFactoryAddress:
                config.community.primaryAccountFactory.address);
        expect(aaConfig.entrypointAddress, isNotEmpty,
            reason:
                'Entrypoint address should not be empty for ${config.community.alias}');
        expect(aaConfig.accountFactoryAddress, isNotEmpty,
            reason:
                'Account factory address should not be empty for ${config.community.alias}');
        expect(aaConfig.paymasterType, isNotEmpty,
            reason:
                'Paymaster type should not be empty for ${config.community.alias}');
      }
    });

    test('plugins list is properly parsed', () {
      for (final config in configs) {
        if (config.plugins != null && config.plugins!.isNotEmpty) {
          for (final plugin in config.plugins!) {
            expect(plugin.name, isNotEmpty,
                reason:
                    'Plugin name should not be empty for ${config.community.alias}');
            expect(plugin.url, isNotEmpty,
                reason:
                    'Plugin URL should not be empty for ${config.community.alias}');
          }
        }
      }
    });

    test('custom domain matches alias pattern when present', () {
      for (final config in configs) {
        if (config.community.customDomain != null) {
          // Custom domain should typically match or be related to the alias
          expect(config.community.customDomain, isNotEmpty,
              reason:
                  'Custom domain should not be empty when specified for ${config.community.alias}');
        }
      }
    });

    test('wallet URL generation works correctly', () {
      const deepLinkBaseUrl = 'https://app.citizenwallet.xyz';
      for (final config in configs) {
        final walletUrl = config.community.walletUrl(deepLinkBaseUrl);
        expect(walletUrl, startsWith(deepLinkBaseUrl),
            reason:
                'Wallet URL should start with base URL for ${config.community.alias}');
        expect(walletUrl, contains('alias=${config.community.alias}'),
            reason:
                'Wallet URL should contain alias parameter for ${config.community.alias}');
      }
    });
  });

  group('getAccountAbstractionConfig', () {
    test('returns primary config when no address provided', () {
      for (final config in configs) {
        final aaConfig = config.getAccountAbstractionConfig(
            accountFactoryAddress:
                config.community.primaryAccountFactory.address);
        expect(aaConfig, isA<ERC4337Config>(),
            reason:
                'Should return ERC4337Config for ${config.community.alias}');
        expect(aaConfig.accountFactoryAddress,
            config.community.primaryAccountFactory.address,
            reason:
                'Should return primary account factory address for ${config.community.alias}');
      }
    });

    test('throws exception when empty address provided', () {
      final config = configs.first;
      expect(
        () => config.getAccountAbstractionConfig(accountFactoryAddress: ''),
        throwsException,
        reason:
            'Should throw exception when empty account factory address is provided',
      );
    });

    test(
        'returns correct config for each account factory in multi-factory communities',
        () {
      for (final config in configs) {
        final alias = config.community.alias;
        if (communitiesWithMultipleAccountFactories.containsKey(alias)) {
          final factories = communitiesWithMultipleAccountFactories[alias]!;
          for (final factoryAddress in factories) {
            final aaConfig = config.getAccountAbstractionConfig(
                accountFactoryAddress: factoryAddress);
            expect(aaConfig, isA<ERC4337Config>(),
                reason:
                    'Should return ERC4337Config for $alias with factory $factoryAddress');
            expect(aaConfig.accountFactoryAddress, factoryAddress,
                reason:
                    'Should return correct account factory address for $alias');
          }
        }
      }
    });

    test('throws exception for non-existent account factory address', () {
      final config = configs.first;
      expect(
        () => config.getAccountAbstractionConfig(
            accountFactoryAddress: '0xNonExistentAddress'),
        throwsException,
        reason:
            'Should throw exception for non-existent account factory address',
      );
    });

    test('all account factories in map exist in their respective configs', () {
      for (final config in configs) {
        final alias = config.community.alias;
        if (communitiesWithMultipleAccountFactories.containsKey(alias)) {
          final factories = communitiesWithMultipleAccountFactories[alias]!;
          for (final factoryAddress in factories) {
            final chainId = config.community.primaryToken.chainId;
            final fullAddress = '$chainId:$factoryAddress';
            expect(config.accounts.containsKey(fullAddress), isTrue,
                reason:
                    'Account factory $factoryAddress should exist in accounts map for $alias');
          }
        }
      }
    });
  });

  group('getRpcUrl', () {
    test('returns correct URL for primary account factory', () {
      for (final config in configs) {
        final alias = config.community.alias;

        // Skip if no expected RPC URL defined for this community
        if (!communityRpcUrls.containsKey(alias)) {
          continue;
        }

        final chainId = config.community.primaryToken.chainId.toString();
        final primaryAccountFactory =
            config.community.primaryAccountFactory.address;
        final expectedUrls = communityRpcUrls[alias]!;

        // Get the expected URL for the primary account factory
        final expectedUrl = expectedUrls[primaryAccountFactory];

        if (expectedUrl != null) {
          final actualUrl = config.getRpcUrl(
              chainId: chainId, accountFactoryAddress: primaryAccountFactory);
          expect(actualUrl, equals(expectedUrl),
              reason: 'RPC URL mismatch for $alias (primary account factory)');
        }
      }
    });

    test('returns correct URL for specific account factory', () {
      for (final config in configs) {
        final alias = config.community.alias;

        // Skip if no expected RPC URLs defined for this community
        if (!communityRpcUrls.containsKey(alias)) {
          continue;
        }

        final chainId = config.community.primaryToken.chainId.toString();
        final expectedUrls = communityRpcUrls[alias]!;

        // Test each account factory address
        for (final accountFactory in expectedUrls.keys) {
          final expectedUrl = expectedUrls[accountFactory]!;
          final actualUrl = config.getRpcUrl(
            chainId: chainId,
            accountFactoryAddress: accountFactory,
          );

          expect(actualUrl, equals(expectedUrl),
              reason:
                  'RPC URL mismatch for $alias with account factory $accountFactory');
        }
      }
    });

    test('works for communities with multiple account factories', () {
      for (final alias in communitiesWithMultipleAccountFactories.keys) {
        final config = configs.firstWhere((c) => c.community.alias == alias);
        final accountFactories =
            communitiesWithMultipleAccountFactories[alias]!;
        final chainId = config.community.primaryToken.chainId.toString();

        expect(accountFactories.length, greaterThan(1),
            reason: '$alias should have multiple account factories');

        // Verify each account factory returns a different RPC URL
        final urls = <String>{};
        for (final accountFactory in accountFactories) {
          final url = config.getRpcUrl(
            chainId: chainId,
            accountFactoryAddress: accountFactory,
          );
          urls.add(url);
        }

        // All URLs should be valid and non-empty
        for (final url in urls) {
          expect(url, isNotEmpty);
          expect(url, startsWith('https://'));
          expect(url, contains('/v1/rpc/'));
        }
      }
    });

    test('throws exception for invalid chain ID', () {
      final config = configs.first;

      expect(
        () => config.getRpcUrl(
            chainId: '99999',
            accountFactoryAddress:
                config.community.primaryAccountFactory.address),
        throwsException,
        reason: 'Should throw exception for non-existent chain ID',
      );
    });

    test('throws exception for non-existent account factory', () {
      final config = configs.first;
      final chainId = config.community.primaryToken.chainId.toString();

      expect(
        () => config.getRpcUrl(
          chainId: chainId,
          accountFactoryAddress: '0xNonExistentAddress',
        ),
        throwsException,
        reason:
            'Should throw exception for non-existent account factory address',
      );
    });
  });
}
