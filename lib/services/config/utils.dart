import 'package:flutter_dotenv/flutter_dotenv.dart';

const Map<String, String> correctedAliases = {
  'wallet': 'wallet.oak.community',
  'oak': 'wallet.oak.community',
  'usdc.polygon': 'app',
};

String fixLegacyAliases(String alias) {
  if (correctedAliases.containsKey(alias)) {
    return correctedAliases[alias]!;
  }

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  return alias == 'localhost' || alias == '' ? defaultAlias : alias;
}

/// migrate the accounts from the accounts migration db (when migrating from old app and you want to put a value in the account secret)
/// hard coded values for these communities (gratitude, bread, wallet.commonshub.brussels, wallet.sfluv.org)
/// if account factory address is '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2', return '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
/// the others just take the primary account factory
const Map<String, String> configV4PrimaryAccountFactoryMap = {
  /****cw-safe (old)*****/
  'ctzn': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  'txirrin': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  'boliviapay': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  'seldesalm': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  'my.techi.be': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  'wallet.kingfishersmedia.io': '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
  /*********/
  'gratitude': '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD',
  'bread': '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9',
  'wallet.commonshub.brussels': '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87',
  'wallet.sfluv.org': '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e',
  /****cw-safe (new)*****/
  'wallet.berachain.sfluv.org': '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
  'laborhour': '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
  'rooted': '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185',
  /*********/
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
};

const String oldSafeFactory = '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2';
const String newSafeFactory = '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185';

/// Returns the correct account factory address for a given community alias during database migration.
///
/// Priority logic:
/// 1. Specific hardcoded overrides for: gratitude, bread, wallet.commonshub.brussels, wallet.sfluv.org
/// 2. Safe factory redirection: if the mapped address is '0x940Cbb155161dc0C4aade27a4826a16Ed8ca0cb2',
///    return '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185' instead
/// 3. General fallback: return the address from the map
/// 4. Safety: if alias not found, return '0x7cC54D54bBFc65d1f0af7ACee5e4042654AF8185'
String getAccountFactoryAddressByAlias(String alias) {
  // List of specific aliases that should keep their original addresses
  const Set<String> hardcodedOverrides = {
    'gratitude',
    'bread',
    'wallet.commonshub.brussels',
    'wallet.sfluv.org',
  };

  // 1. Check if this is a hardcoded override
  if (hardcodedOverrides.contains(alias)) {
    return configV4PrimaryAccountFactoryMap[alias]!;
  }

  // Get the address from the map
  final String? mappedAddress = configV4PrimaryAccountFactoryMap[alias];

  // 4. Safety: if alias not found, return new safe factory
  if (mappedAddress == null) {
    return newSafeFactory;
  }

  // 2. Safe factory redirection: if old safe factory, return new safe factory
  if (mappedAddress == oldSafeFactory) {
    return newSafeFactory;
  }

  // 3. General fallback: return the mapped address
  return mappedAddress;
}
