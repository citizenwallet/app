import 'dart:convert';

import 'package:citizenwallet/services/config/utils.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DBAccount {
  final String id;
  final String alias;
  final EthereumAddress address;
  final String name;
  final UserHandle? userHandle;
  final String? username;
  EthPrivateKey? privateKey;
  final ProfileV1? profile;

  DBAccount({
    required this.alias,
    required this.address,
    required this.name,
    this.username,
    this.privateKey,
    this.profile,
  })  : id = getAccountID(address, alias),
        userHandle = username != null ? UserHandle(username, alias) : null;

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alias': alias,
      'address': address.hexEip55,
      if (name.isNotEmpty) 'name': name,
      'username': username,
      'privateKey':
          privateKey != null ? bytesToHex(privateKey!.privateKey) : null,
      if (profile != null) 'profile': jsonEncode(profile!.toJson()),
    };
  }

  // fromMap
  factory DBAccount.fromMap(Map<String, dynamic> map) {
    return DBAccount(
      alias: map['alias'],
      address: EthereumAddress.fromHex(map['address']),
      name: map['name'],
      username: map['username'],
      privateKey: map['privateKey'] != null
          ? EthPrivateKey.fromHex(map['privateKey'])
          : null,
      profile: map['profile'] != null
          ? ProfileV1.fromJson(jsonDecode(map['profile']))
          : null,
    );
  }
}

class DBAccountV4 extends DBAccount {
  final EthereumAddress accountFactoryAddress;

  DBAccountV4({
    required super.alias,
    required super.address,
    required super.name,
    super.username,
    super.privateKey,
    super.profile,
    required this.accountFactoryAddress,
  }) : super();

  // Override toMap to include accountFactoryAddress and update the ID format
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    // Update the ID to the V4 format: address@accountFactoryAddress@alias
    map['id'] = getAccountIdV4(
      address: address,
      alias: alias,
      accountFactoryAddress: accountFactoryAddress,
    );
    map['accountFactoryAddress'] = accountFactoryAddress.hexEip55;
    return map;
  }

  // fromMap factory for the V4 structure
  factory DBAccountV4.fromMap(Map<String, dynamic> map) {
    return DBAccountV4(
      alias: map['alias'],
      address: EthereumAddress.fromHex(map['address']),
      name: map['name'],
      username: map['username'],
      accountFactoryAddress:
          EthereumAddress.fromHex(map['accountFactoryAddress']),
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

String getAccountIdV4({
  required EthereumAddress address,
  required String alias,
  required EthereumAddress accountFactoryAddress,
}) {
  return '${address.hexEip55}@${accountFactoryAddress.hexEip55}@$alias';
}

class UserHandle {
  final String username;
  final String communityAlias;

  const UserHandle(this.username, this.communityAlias);

  factory UserHandle.fromUserHandle(String userHandle) {
    final parts = userHandle.split('@');
    if (parts.length != 2) {
      throw FormatException('Invalid user handle format: $userHandle');
    }
    return UserHandle(parts[0], parts[1]);
  }

  @override
  String toString() => '$username@$communityAlias';
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
        username TEXT,
        privateKey TEXT,
        profile TEXT,
        accountFactoryAddress TEXT NOT NULL
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
        'UPDATE $name SET privateKey = NULL',
      ],
      3: [
        'ALTER TABLE $name ADD COLUMN username TEXT DEFAULT NULL',
      ],
      4: [
        'ALTER TABLE $name ADD COLUMN accountFactoryAddress TEXT DEFAULT ""',
        'PopulateAccountFactoryAddressMigration',
        'InsertRowsInV4IdFormatMigration', // Insert the rows in the new format $address@$accountFactoryAddress@$alias
        
      ]
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      if (queries != null) {
        for (final query in queries) {
          try {
            switch (query) {
              case 'PopulateAccountFactoryAddressMigration':
                await _populateAccountFactoryAddressMigration(db, name);
                continue;

              case 'InsertRowsInV4IdFormatMigration':
                await _insertRowsInV4IdFormatMigration(db, name);
                continue;
            }

            await db.execute(query);
          } catch (e, s) {
            debugPrint('Migration error: $e');
            debugPrintStack(stackTrace: s);
          }
        }
      }
    }
  }

  Future<void> _populateAccountFactoryAddressMigration(
      Database db, String name) async {
    // Work directly with raw DB data, not DBAccount objects
    List<Map<String, dynamic>> accounts = await db.query(name);

    for (final Map<String, dynamic> account in accounts) {
      final alias = account['alias'] as String;
      final oldId = account['id'] as String;

      final accountFactoryAddress = getAccountFactoryAddressByAlias(alias);

      // Update the accountFactoryAddress column (ID still in old format $address@$alias)
      await db.update(
        name,
        {'accountFactoryAddress': accountFactoryAddress},
        where: 'id = ?',
        whereArgs: [oldId],
      );
    }
  }

  Future<void> _insertRowsInV4IdFormatMigration(
    Database db,
    String name,
  ) async {
    List<Map<String, dynamic>> accounts = await db.query(name);

    // Create all DBAccountV4 objects
    final List<DBAccountV4> dbAccountsV4 = [];
    for (final Map<String, dynamic> account in accounts) {
      final dbAccountV4 = DBAccountV4(
        alias: account['alias'] as String,
        address: EthereumAddress.fromHex(account['address'] as String),
        name: account['name'] as String,
        username: account['username'] as String?,
        privateKey: account['privateKey'] != null
            ? EthPrivateKey.fromHex(account['privateKey'] as String)
            : null,
        profile: account['profile'] != null
            ? ProfileV1.fromJson(jsonDecode(account['profile'] as String))
            : null,
        accountFactoryAddress:
            EthereumAddress.fromHex(account['accountFactoryAddress'] as String),
      );
      dbAccountsV4.add(dbAccountV4);
    }

    // Batch insert new accounts
    final batch = db.batch();
    for (final dbAccountV4 in dbAccountsV4) {
      batch.insert(
        name,
        dbAccountV4.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // Delete old accounts only after successful insert
    for (final Map<String, dynamic> account in accounts) {
      await db.delete(
        name,
        where: 'id = ?',
        whereArgs: [account['id']],
      );
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

  Future<List<DBAccountV4>> all() async {
    final List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBAccountV4.fromMap(maps[i]);
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
