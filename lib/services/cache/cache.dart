import 'package:citizenwallet/services/db/db.dart';

abstract class Cache {
  final DBService _db;
  final Duration _ttl;

  DBService get db => _db;
  Duration get ttl => _ttl;

  Cache(this._db, this._ttl);

  bool shouldReplace(DateTime lastUpdate) {
    return DateTime.now().difference(lastUpdate) > _ttl;
  }

  Future<dynamic> get(String key, Future<dynamic> Function() onMiss);

  Future<void> set(String key, dynamic value);

  Future<void> delete(String key);
}
