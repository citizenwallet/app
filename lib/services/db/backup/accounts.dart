import 'dart:convert';

import 'package:citizenwallet/services/config/utils.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class DBAccount {
  final String id;
  final String alias;
  final EthereumAddress address;
  final EthereumAddress accountFactoryAddress;
  final String name;
  final UserHandle? userHandle;
  final String? username;
  EthPrivateKey? privateKey;
  final ProfileV1? profile;

  DBAccount({
    required this.alias,
    required this.address,
    required this.accountFactoryAddress,
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
      'accountFactoryAddress': accountFactoryAddress.hexEip55,
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
      accountFactoryAddress:
          EthereumAddress.fromHex(map['accountFactoryAddress']),
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

String getAccountID(EthereumAddress address, String alias) {
  return '${address.hexEip55}@$alias';
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
        // bad migration,https://github.com/citizenwallet/app/blob/d4f72940e11f1812c34dfb47c0bffe7488a1c32e/lib/services/db/backup/accounts.dart#L123
      ],
      5: [
        // This migration handles both paths:
        // - AppKevin (v4 -> v5): column already exists, just populate
        // - AppOthers (v3 -> v5): column doesn't exist, add it then populate
        'AddAccountFactoryAddressIfNotExists',
        'PopulateAccountFactoryAddressMigration',
        'CleanDirtyV4Accounts',
      ]
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      if (queries != null) {
        for (final query in queries) {
          try {
            switch (query) {
              case 'AddAccountFactoryAddressIfNotExists':
                await _addAccountFactoryAddressIfNotExists(db, name);
                continue;

              case 'PopulateAccountFactoryAddressMigration':
                await _populateAccountFactoryAddressMigration(db, name);
                continue;

              case 'CleanDirtyV4Accounts':
                await _cleanDirtyV4Accounts(db, name);
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

  Future<void> _addAccountFactoryAddressIfNotExists(
    Database db,
    String name,
  ) async {
    final columnName = 'accountFactoryAddress';

    // Check if column exists
    final tableInfo = await db.rawQuery('PRAGMA table_info($name)');
    final hasColumn = tableInfo.any((col) => col['name'] == columnName);

    if (hasColumn) {
      return;
    }

    await db
        .execute('ALTER TABLE $name ADD COLUMN $columnName  TEXT DEFAULT ""');
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

  Future<void> _cleanDirtyV4Accounts(Database db, String name) async {
    // Get all accounts from the database
    List<Map<String, dynamic>> accounts = await db.query(name);

    for (final Map<String, dynamic> account in accounts) {
      final String currentId = account['id'] as String;
      final String alias = account['alias'] as String;
      final String addressStr = account['address'] as String;
      final String accountFactoryAddressStr =
          account['accountFactoryAddress'] as String;

      // Construct what the ID should be in the old format
      final String oldFormatId = getAccountID(EthereumAddress.fromHex(addressStr), alias);

      // Construct what the ID would be in the new (bad) format
      final String newFormatId = '$addressStr@$accountFactoryAddressStr@$alias';

      // Check if current ID matches the new (bad) format
      if (currentId == newFormatId) {
        debugPrint('Cleaning dirty account: $currentId -> $oldFormatId');

        // Check if an account with the old format ID already exists
        final existingOldFormat = await db.query(
          name,
          where: 'id = ?',
          whereArgs: [oldFormatId],
        );

        if (existingOldFormat.isEmpty) {
          // No conflict: Insert new row with old ID format
          final Map<String, dynamic> cleanAccount = Map.from(account);
          cleanAccount['id'] = oldFormatId;

          await db.insert(
            name,
            cleanAccount,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          debugPrint('Inserted clean account with old format ID: $oldFormatId');
        } else {
          // Conflict exists: Keep the existing old format, just log
          debugPrint(
              'Old format ID already exists, keeping existing: $oldFormatId');
        }

        // Delete the row with new (bad) format ID
        await db.delete(
          name,
          where: 'id = ?',
          whereArgs: [currentId],
        );

        debugPrint('Deleted dirty account with new format ID: $currentId');
      } else if (currentId == oldFormatId) {
        // Already in correct old format, do nothing
        debugPrint('Account already in correct format: $currentId');
      } else {
        // Unexpected format - force to old format
        debugPrint(
            'Warning: Unexpected ID format, forcing to old format: $currentId -> $oldFormatId');

        // Check if an account with the old format ID already exists
        final existingOldFormat = await db.query(
          name,
          where: 'id = ?',
          whereArgs: [oldFormatId],
        );

        if (existingOldFormat.isEmpty) {
          // No conflict: Insert new row with old ID format, preserving all other columns
          final Map<String, dynamic> cleanAccount = Map.from(account);
          cleanAccount['id'] = oldFormatId;

          await db.insert(
            name,
            cleanAccount,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          debugPrint(
              'Inserted account with corrected old format ID: $oldFormatId');
        } else {
          // Conflict exists: Keep the existing old format
          debugPrint(
              'Old format ID already exists, keeping existing: $oldFormatId');
        }

        // Delete the row with unexpected format ID
        await db.delete(
          name,
          where: 'id = ?',
          whereArgs: [currentId],
        );

        debugPrint('Deleted account with unexpected format ID: $currentId');
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
