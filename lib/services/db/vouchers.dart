import 'dart:convert';

import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite_common/sqflite.dart';

class DBVoucher {
  final String address;
  final String alias;
  final String name;
  final String balance;
  final String voucher;
  final String salt;
  final String creator;
  final bool archived;
  final bool legacy;
  DateTime createdAt = DateTime.now();

  DBVoucher({
    required this.address,
    required this.alias,
    required this.name,
    required this.balance,
    required this.voucher,
    required this.salt,
    required this.creator,
    this.archived = false,
    this.legacy = false,
  });

  DBVoucher.read({
    required this.address,
    required this.alias,
    required this.name,
    required this.balance,
    required this.voucher,
    required this.salt,
    required this.creator,
    required this.createdAt,
    required this.archived,
    required this.legacy,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'alias': alias,
      'name': name,
      'balance': balance,
      'voucher': voucher,
      'salt': salt,
      'creator': creator,
      'createdAt': createdAt.toIso8601String(),
      'archived': archived ? 1 : 0,
      'legacy': legacy ? 1 : 0,
    };
  }

  factory DBVoucher.fromMap(Map<String, dynamic> map) {
    return DBVoucher.read(
      address: map['address'],
      alias: map['alias'],
      name: map['name'],
      balance: map['balance'],
      voucher: map['voucher'],
      salt: map['salt'],
      creator: map['creator'],
      createdAt: DateTime.parse(map['createdAt']),
      archived: map['archived'] == 1,
      legacy: map['legacy'] == 1,
    );
  }

  // to json
  String toJson() => json.encode(toMap());
}

class VouchersTable extends DBTable {
  VouchersTable(Database db) : super(db);

  // The name of the table
  @override
  String get name => 't_voucher';

  @override
  String get createQuery => '''
  CREATE TABLE $name (
    address TEXT PRIMARY KEY,
    alias TEXT NOT NULL,
    name TEXT NOT NULL,
    balance TEXT NOT NULL,
    voucher TEXT NOT NULL UNIQUE,
    salt TEXT NOT NULL,
    creator TEXT NOT NULL DEFAULT '',
    createdAt TEXT NOT NULL,
    archived INTEGER DEFAULT 0,
    legacy INTEGER DEFAULT 0
  )
''';

  // Creates the table and an index on the name column if they do not already exist
  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_alias ON $name (alias)
      ''');

    await db.execute('''
        CREATE INDEX idx_${name}_name ON $name (name)
      ''');
  }

  // Migrates the table
  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrations = {
      2: [
        createQuery,
        '''
          CREATE INDEX idx_${name}_token ON $name (token)
        ''',
        '''
          CREATE INDEX idx_${name}_name ON $name (name)
        ''',
      ],
      3: [
        '''
          DROP TABLE IF EXISTS $name
        ''',
        createQuery,
        '''
          CREATE INDEX idx_${name}_token ON $name (token)
        ''',
        '''
          CREATE INDEX idx_${name}_name ON $name (name)
        ''',
      ],
      4: [
        '''
          ALTER TABLE $name ADD COLUMN creator TEXT NOT NULL DEFAULT ''
        ''',
      ],
      5: [
        '''
          ALTER TABLE $name ADD COLUMN alias TEXT NOT NULL DEFAULT 'global'
        ''',
        '''
          CREATE INDEX idx_${name}_alias ON $name (alias)
        ''',
        '''
          DROP INDEX idx_${name}_token
        ''',
        '''
          ALTER TABLE $name DROP COLUMN token
        '''
      ],
      7: [
        '''
          ALTER TABLE $name ADD COLUMN legacy INTEGER DEFAULT 0
        ''',
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

  // Inserts a new voucher into the table
  Future<void> insert(DBVoucher voucher) async {
    await db.insert(name, voucher.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieves a voucher from the table by its address
  Future<DBVoucher?> get(String address) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: null, where: 'address = ?', whereArgs: [address], limit: 1);

    if (maps.isNotEmpty) {
      return DBVoucher.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Retrieves all vouchers from the table
  Future<List<DBVoucher>> getAll() async {
    List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBVoucher.fromMap(maps[i]);
    });
  }

  // Retrieves all vouchers from the table by alias
  Future<List<DBVoucher>> getAllByAlias(String token) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: null,
        where: 'alias = ?',
        whereArgs: [token],
        orderBy: 'createdAt DESC');

    return List.generate(maps.length, (i) {
      return DBVoucher.fromMap(maps[i]);
    });
  }

  // Updates a voucher in the table
  Future<void> update(DBVoucher voucher) async {
    await db.update(name, voucher.toMap(),
        where: 'address = ?', whereArgs: [voucher.address]);
  }

  // Updates a voucher's balance
  Future<void> updateBalance(String address, String balance) async {
    await db.update(name, {'balance': balance},
        where: 'address = ?', whereArgs: [address]);
  }

  // Archives a voucher
  Future<void> archive(String address) async {
    await db.update(name, {'archived': 1},
        where: 'address = ?', whereArgs: [address]);
  }

  // Deletes a voucher from the table by its address
  Future<void> delete(String address) async {
    await db.delete(name, where: 'address = ?', whereArgs: [address]);
  }
}
