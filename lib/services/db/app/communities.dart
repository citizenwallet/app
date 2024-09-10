class DBCommunity {
  final String alias; // index
  final int version;
  final bool hidden;
  final bool online;
  final String config;

  DBCommunity({
    required this.alias,
    required this.version,
    required this.hidden,
    required this.config,
    this.online = true,
  });
}
