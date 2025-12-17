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
/// hard coded values for these communities
/// the others just take the primary account factory
const Map<String, String> migrationAccountFactoryAddresses = {
  'gratitude': '0xAE6E18a9Cd26de5C8f89B886283Fc3f0bE5f04DD',
  'bread': '0xAE76B1C6818c1DD81E20ccefD3e72B773068ABc9',
  'wallet.commonshub.brussels': '0x307A9456C4057F7C7438a174EFf3f25fc0eA6e87',
  'wallet.sfluv.org': '0x5e987a6c4bb4239d498E78c34e986acf29c81E8e',
};
