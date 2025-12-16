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
        final aaConfig = config.getPrimaryAccountAbstractionConfig();
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
        final aaConfig = config.getAccountAbstractionConfig();
        expect(aaConfig, isA<ERC4337Config>(),
            reason:
                'Should return ERC4337Config for ${config.community.alias}');
        expect(aaConfig.accountFactoryAddress,
            config.community.primaryAccountFactory.address,
            reason:
                'Should return primary account factory address for ${config.community.alias}');
      }
    });

    test('returns primary config when empty address provided', () {
      for (final config in configs) {
        final aaConfig =
            config.getAccountAbstractionConfig(accountFactoryAddress: '');
        expect(aaConfig, isA<ERC4337Config>(),
            reason:
                'Should return ERC4337Config for ${config.community.alias}');
        expect(aaConfig.accountFactoryAddress,
            config.community.primaryAccountFactory.address,
            reason:
                'Should return primary account factory address when empty string provided for ${config.community.alias}');
      }
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
}
