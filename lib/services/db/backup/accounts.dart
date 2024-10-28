import 'dart:convert';

import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DBAccount {
  final String id;
  final String alias;
  final EthereumAddress address;
  final String name;
  EthPrivateKey? privateKey;
  final ProfileV1? profile;

  DBAccount({
    required this.alias,
    required this.address,
    required this.name,
    this.privateKey,
    this.profile,
  }) : id = getAccountID(address, alias);

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alias': alias,
      'address': address.hexEip55,
      'name': name,
      'privateKey': privateKey != null ? bytesToHex(privateKey!.privateKey) : null,
      if (profile != null) 'profile': jsonEncode(profile!.toJson()),
    };
  }

  // fromMap
  factory DBAccount.fromMap(Map<String, dynamic> map) {
    return DBAccount(
      alias: map['alias'],
      address: EthereumAddress.fromHex(map['address']),
      name: map['name'],
      privateKey: map['privateKey'] != null
          ? EthPrivateKey.fromHex(map['privateKey'])
          : null,
      profile: map['profile'] != null
          ? ProfileV1.fromJson(jsonDecode(map['profile']))
          : null,
    );
  }
}

String getAccountID(EthereumAddress address, String alias) {
  return '${address.hexEip55}@$alias';
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
        name TEXT NOT NULL,
        privateKey TEXT,
        profile TEXT
      )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrations = {
       2: [
        // Skip the broken migration
      ],
      3: [
        'UPDATE $name SET privateKey = NULL',
      ],
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      print('Migrating accounts from $oldVersion to $newVersion: $queries');

      if (queries != null) {
        for (final query in queries) {
          await db.execute(query);
        }
      }
    }
  }

  // get account by id
  Future<DBAccount?> get(EthereumAddress address, String alias) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'id = ?',
      whereArgs: [getAccountID(address, alias)],
    );

    if (maps.isEmpty) {
      return null;
    }

    return DBAccount.fromMap(maps.first);
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

  Future<void> delete(EthereumAddress address, String alias) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [getAccountID(address, alias)],
    );
  }

  // delete all
  Future<void> deleteAll() async {
    await db.delete(name);
  }

  Future<List<DBAccount>> all() async {
    final List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBAccount.fromMap(maps[i]);
    });
  }

  // get all accounts for alias
  Future<List<DBAccount>> allForAlias(String alias) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'alias = ?',
      whereArgs: [alias],
    );

    return List.generate(maps.length, (i) {
      return DBAccount.fromMap(maps[i]);
    });
  }
}
