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

  final String defaultAlias = dotenv.env['SINGLE_COMMUNITY_ALIAS'] ??
      dotenv.get('DEFAULT_COMMUNITY_ALIAS');

  return alias == 'localhost' || alias == '' ? defaultAlias : alias;
}
