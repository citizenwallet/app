import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';

class DBAccount {
  final String id;
  final String alias;
  final String address;
  final String name;

  DBAccount({
    required this.alias,
    required this.address,
    required this.name,
  }) : id = '$alias|$address';

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alias': alias,
      'address': address,
      'name': name,
    };
  }

  // fromMap
  factory DBAccount.fromMap(Map<String, dynamic> map) {
    return DBAccount(
      alias: map['alias'],
      address: map['address'],
      name: map['name'],
    );
  }
}

class AccountsTable extends DBTable {
  AccountsTable(super.db);

  @override
  String get name => 't_accounts';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
        id TEXT PRIMARY KEY,
        alias TEXT NOT NULL,
        address TEXT NOT NULL,
        name TEXT NOT NULL
      )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrations = {
      8: [
        createQuery,
      ],
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      if (queries != null) {
        for (final query in queries) {
          await db.execute(query);
        }
      }
    }
  }

  Future<void> insert(DBAccount account) async {
    await db.insert(
      name,
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(DBAccount account) async {
    await db.update(
      name,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> delete(DBAccount account) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<List<DBAccount>> all() async {
    final List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBAccount.fromMap(maps[i]);
    });
  }
}
