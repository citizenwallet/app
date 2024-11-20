import 'package:citizenwallet/services/cache/cache.dart';
import 'package:citizenwallet/services/db/account/contacts.dart';
import 'package:citizenwallet/services/db/account/db.dart';

class ContactsCache extends Cache {
  static final ContactsCache _instance = ContactsCache._internal(
    AccountDBService(),
    const Duration(seconds: 60),
  );

  factory ContactsCache() {
    return _instance;
  }

  ContactsCache._internal(super._db, super._ttl) {
    _table = db.contacts;
  }

  late ContactTable _table;

  void init(AccountDBService db) {
    _table = db.contacts;
  }

  @override
  Future<DBContact?> get(String key, Future<dynamic> Function() onMiss) async {
    final value = await _table.get(key);

    if (value == null) {
      final result = await onMiss();
      if (result == null || result is! DBContact) {
        return null;
      }
      set(key, result);
      return result;
    }

    if (shouldReplace(value.updatedAt)) {
      // do something and update db
      onMiss().then((result) {
        if (result == null || result is! DBContact) {
          return null;
        }
        set(key, result);
      });
    }

    return value;
  }

  @override
  Future<void> set(String key, dynamic value) {
    if (value is! DBContact) {
      throw Exception('Key not found');
    }

    return _table.upsert(value);
  }

  @override
  Future<void> delete(String key) {
    return _table.delete(key);
  }
}
