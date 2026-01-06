import 'package:citizenwallet/services/config/utils.dart';
import 'package:test/test.dart';

/// Expected outcomes map for testing getAccountFactoryAddressByAlias
/// Covers all four logic branches:
/// 1. Hardcoded overrides (gratitude, bread, wallet.commonshub.brussels, wallet.sfluv.org)
/// 2. Safe factory redirection (old safe factory -> new safe factory)
/// 3. General fallback (return mapped address as-is)
/// 4. Unknown alias (return new safe factory as safety default)
const Map<String, String> expectedOutcomes = {
  // 1. Hardcoded Overrides - these should return their ORIGINAL addresses
  'gratitude': '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD',
  'bread': '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9',
  'wallet.commonshub.brussels': '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87',
  'wallet.sfluv.org': '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e',

  // 2. Safe Factory Redirection - old safe factory should redirect to new safe factory
  'ctzn': newSafeFactory,
  'txirrin': newSafeFactory,
  'boliviapay': newSafeFactory,
  'seldesalm': newSafeFactory,
  'my.techi.be': newSafeFactory,
  'wallet.kingfishersmedia.io': newSafeFactory,

  // 3. General Fallback - return mapped addresses as-is
  'wallet.berachain.sfluv.org': newSafeFactory,
  'laborhour': newSafeFactory,
  'rooted': newSafeFactory,
  'wallet.pay.brussels': '0xBABCf159c4e3186cf48e4a48bC0AeC17CF9d90FE',
  'wallet.regensunite.earth': '0x9406Cc6185a346906296840746125a0E44976454',
  'gt.celo': '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD',
  'ceur.celo': '0xdA529eBEd3D459dac9d9D3D45b8Cae2D5796c098',
  'eure.polygon': '0x5bA08d9fC7b90f79B2b856bdB09FC9EB32e83616',
  'app': '0x270758454C012A1f51428b68aE473D728CCdFe88',
  'usdc.base': '0x05e2Fb34b4548990F96B3ba422eA3EF49D5dAa99',
  'wallet.oak.community': '0x9406Cc6185a346906296840746125a0E44976454',
  'sbc.polygon': '0x3Be13D9325C8C9174C3819d3d868D5D3aB8Fc8a5',
  'zinne': '0x11af2639817692D2b805BcE0e1e405E530B20006',
  'timebank.regensunite.earth': '0x39b77d77f7677997871b304094a05295eb71e240',
  'moos': '0x671f0662de72268d0f3966Fb62dFc6ee6389e244',
  'selcoupdepouce': '0x4Cc883b7E8E0BCB2e293703EF06426F9b4A5A284',
  'cit.celo': '0x0a9f4B7e7Ec393fF25dc9267289Be259Ec3FB970',
  'wallet.wolugo.be': '0x8474153A00C959f2cB64852949954DBC68415Bb3',
  'wtc.celo': '0xE79E19594A749330036280c685E2719d58d99052',
  'testnet-ethldn': '0xc1654087C580f868F08E34cd1c01eDB1d3673b82',
  'celo-c.citizenwallet.xyz': '0xcd8b1B9E760148c5026Bc5B0D56a5374e301FDcA',

  // 4. Unknown Alias - should return new safe factory as safety default
  'non-existent-alias': newSafeFactory,
  'unknown-community': newSafeFactory,
  'test-alias-not-in-map': newSafeFactory,
};

void main() {
  group('getAccountFactoryAddressByAlias', () {
    test('returns correct addresses for all test cases', () {
      expectedOutcomes.forEach((alias, expectedAddress) {
        final result = getAccountFactoryAddressByAlias(alias);
        expect(
          result,
          expectedAddress,
          reason: 'Failed for alias: $alias',
        );
      });
    });

    group('specific logic branch tests', () {
      test('hardcoded overrides return original addresses', () {
        // These four should return their original addresses, not redirected
        expect(
          getAccountFactoryAddressByAlias('gratitude'),
          '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD',
          reason: 'gratitude should return its original address',
        );
        expect(
          getAccountFactoryAddressByAlias('bread'),
          '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9',
          reason: 'bread should return its original address',
        );
        expect(
          getAccountFactoryAddressByAlias('wallet.commonshub.brussels'),
          '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87',
          reason:
              'wallet.commonshub.brussels should return its original address',
        );
        expect(
          getAccountFactoryAddressByAlias('wallet.sfluv.org'),
          '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e',
          reason: 'wallet.sfluv.org should return its original address',
        );
      });

      test('old safe factory addresses are redirected to new safe factory', () {
        // All these aliases map to old safe factory and should be redirected
        final oldSafeFactoryAliases = [
          'ctzn',
          'txirrin',
          'boliviapay',
          'seldesalm',
          'my.techi.be',
          'wallet.kingfishersmedia.io',
        ];

        for (final alias in oldSafeFactoryAliases) {
          expect(
            getAccountFactoryAddressByAlias(alias),
            newSafeFactory,
            reason: '$alias should be redirected to new safe factory',
          );
        }
      });

      test('general fallback returns mapped addresses as-is', () {
        // Sample of aliases that should return their mapped addresses unchanged
        expect(
          getAccountFactoryAddressByAlias('wallet.pay.brussels'),
          '0xBABCf159c4e3186cf48e4a48bC0AeC17CF9d90FE',
        );
        expect(
          getAccountFactoryAddressByAlias('app'),
          '0x270758454C012A1f51428b68aE473D728CCdFe88',
        );
        expect(
          getAccountFactoryAddressByAlias('usdc.base'),
          '0x05e2Fb34b4548990F96B3ba422eA3EF49D5dAa99',
        );
      });

      test('unknown aliases return new safe factory as default', () {
        // Test various unknown aliases
        expect(
          getAccountFactoryAddressByAlias('non-existent-alias'),
          newSafeFactory,
        );
        expect(
          getAccountFactoryAddressByAlias('unknown-community'),
          newSafeFactory,
        );
        expect(
          getAccountFactoryAddressByAlias('random-test-123'),
          newSafeFactory,
        );
      });
    });
  });
}
