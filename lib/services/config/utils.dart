const Map<String, String> correctedAliases = {
  'wallet': 'wallet.oak.community',
  'oak': 'wallet.oak.community',
  'usdc.polygon': 'app',
};

String fixLegacyAliases(String alias) {
  if (correctedAliases.containsKey(alias)) {
    return correctedAliases[alias]!;
  }

  return alias == 'localhost' ? 'app' : alias;
}
