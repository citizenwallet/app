import 'dart:convert';

import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';

class DBVoucher {
  final String address;
  final String name;
  final String balance;
  final String voucher;
  final String salt;
  DateTime createdAt = DateTime.now();

  DBVoucher({
    required this.address,
    required this.name,
    required this.balance,
    required this.voucher,
    required this.salt,
  });

  DBVoucher.read({
    required this.address,
    required this.name,
    required this.balance,
    required this.voucher,
    required this.salt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'name': name,
      'balance': balance,
      'voucher': voucher,
      'salt': salt,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DBVoucher.fromMap(Map<String, dynamic> map) {
    return DBVoucher.read(
      address: map['address'],
      name: map['name'],
      balance: map['balance'],
      voucher: map['voucher'],
      salt: map['salt'],
      createdAt: DateTime.parse(map['createdAt']),
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
    address INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    balance TEXT NOT NULL,
    voucher TEXT NOT NULL UNIQUE,
    salt TEXT NOT NULL,
    createdAt TEXT NOT NULL
  )
''';

  // Creates the table and an index on the name column if they do not already exist
  @override
  Future<void> migrate(Database db, int version) async {
    if (version <= 1) {
      return;
    }

    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_name ON $name (name)
      ''');
  }

  // Inserts a new voucher into the table
  Future<void> insertVoucher(DBVoucher voucher) async {
    await db.insert(name, voucher.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Retrieves a voucher from the table by its address
  Future<DBVoucher?> getVoucher(int address) async {
    List<Map<String, dynamic>> maps = await db.query(name,
        columns: null, where: 'address = ?', whereArgs: [address], limit: 1);

    if (maps.isNotEmpty) {
      return DBVoucher.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Retrieves all vouchers from the table
  Future<List<DBVoucher>> getAllVouchers() async {
    List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBVoucher.fromMap(maps[i]);
    });
  }

  // Updates a voucher in the table
  Future<void> updateVoucher(DBVoucher voucher) async {
    await db.update(name, voucher.toMap(),
        where: 'address = ?', whereArgs: [voucher.address]);
  }

  // Deletes a voucher from the table by its address
  Future<void> deleteVoucher(int address) async {
    await db.delete(name, where: 'address = ?', whereArgs: [address]);
  }
}
