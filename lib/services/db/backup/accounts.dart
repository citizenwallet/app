import 'dart:convert';

import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/backup/legacy.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
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
  final String accountFactoryAddress;
  EthPrivateKey? privateKey;
  final ProfileV1? profile;

  DBAccount({
    required this.alias,
    required this.address,
    required this.name,
    required this.accountFactoryAddress,
    this.username,
    this.privateKey,
    this.profile,
  })  : id = getAccountID(address, alias, accountFactoryAddress),
        userHandle = username != null ? UserHandle(username, alias) : null;

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alias': alias,
      'address': address.hexEip55,
      if (name.isNotEmpty) 'name': name,
      'username': username,
      'accountFactoryAddress': accountFactoryAddress,
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
      accountFactoryAddress: map['accountFactoryAddress'] ?? '',
      privateKey: map['privateKey'] != null
          ? EthPrivateKey.fromHex(map['privateKey'])
          : null,
      profile: map['profile'] != null
          ? ProfileV1.fromJson(jsonDecode(map['profile']))
          : null,
    );
  }
}

String getAccountID(
    EthereumAddress address, String alias, String accountFactoryAddress) {
  return '${address.hexEip55}@$accountFactoryAddress@$alias';
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
        accountFactoryAddress TEXT NOT NULL,
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
        'UPDATE $name SET privateKey = NULL',
      ],
      3: [
        'ALTER TABLE $name ADD COLUMN username TEXT DEFAULT NULL',
      ],
      4: [
        'ALTER TABLE $name ADD COLUMN accountFactoryAddress TEXT',
        'UPDATE $name SET accountFactoryAddress = "" WHERE accountFactoryAddress IS NULL',
      ]
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      if (queries != null) {
        for (final query in queries) {
          try {
            await db.execute(query);
          } catch (e, s) {
            debugPrint('Migration error: $e');
            debugPrintStack(stackTrace: s);
          }
        }
      }
    }
  }

  Future<List<LegacyDBAccount>> getAllLegacyDBAccounts() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'accountFactoryAddress IS NULL OR accountFactoryAddress = ""',
    );

    return List.generate(maps.length, (i) {
      return LegacyDBAccount.fromMap(maps[i]);
    });
  }

  /// Converts a LegacyDBAccount to a DBAccount
  /// For legacy accounts, we use a default account factory address
  DBAccount convertLegacyToDBAccount(LegacyDBAccount legacyAccount) {
    return DBAccount(
      alias: legacyAccount.alias,
      address: legacyAccount.address,
      name: legacyAccount.name,
      username: legacyAccount.username,
      accountFactoryAddress: '',
      privateKey: legacyAccount.privateKey,
      profile: legacyAccount.profile,
    );
  }

  // get account by id
  Future<DBAccount?> get(EthereumAddress address, String alias,
      String accountFactoryAddress) async {
    final accountId = getAccountID(address, alias, accountFactoryAddress);

    if (accountFactoryAddress.isEmpty) {
      var maps = await db.query(
        name,
        where: 'id = ?',
        whereArgs: [accountId],
      );

      if (maps.isNotEmpty) {
        final account = DBAccount.fromMap(maps.first);
        return account;
      }

      final oldFormatId = '${address.hexEip55}@$alias';
      maps = await db.query(
        name,
        where: 'id = ?',
        whereArgs: [oldFormatId],
      );

      if (maps.isNotEmpty) {
        final account = DBAccount.fromMap(maps.first);
        return account;
      }

      maps = await db.query(
        name,
        where: 'address = ? AND alias = ?',
        whereArgs: [address.hexEip55, alias],
      );

      if (maps.isNotEmpty) {
        final account = DBAccount.fromMap(maps.first);
        return account;
      }

      return null;
    }

    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'id = ?',
      whereArgs: [accountId],
    );

    if (maps.isEmpty) {
      return null;
    }

    final account = DBAccount.fromMap(maps.first);
    return account;
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

  Future<void> delete(EthereumAddress address, String alias,
      String accountFactoryAddress) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [getAccountID(address, alias, accountFactoryAddress)],
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
