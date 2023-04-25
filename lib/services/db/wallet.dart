import 'dart:convert';

import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';

// class representing a wallet from WalletTable
class DBWallet {
  final int id;
  final String type;
  final String name;
  final String address;
  final int balance;
  final String wallet;

  DBWallet({
    required this.id,
    required this.type,
    required this.name,
    required this.address,
    required this.balance,
    required this.wallet,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_type': type,
      'name': name,
      'address': address,
      'balance': balance,
      'wallet': wallet,
    };
  }

  factory DBWallet.fromMap(Map<String, dynamic> map) {
    return DBWallet(
      id: map['id'],
      type: map['wallet_type'],
      name: map['name'],
      address: map['address'],
      balance: map['balance'],
      wallet: map['wallet'],
    );
  }
}

class WalletTable extends DBTable {
  WalletTable(Database db) : super(db);

  @override
  String get name => 't_wallet';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      id INTEGER PRIMARY KEY,
      wallet_type TEXT NOT NULL,
      name TEXT NOT NULL,
      address TEXT NOT NULL,
      balance INTEGER NOT NULL,
      wallet TEXT NOT NULL
    )
  ''';

  @override
  Future<void> migrate(Database db, int version) async {
    if (version == 1) {
      await db.execute(createQuery);
    }
  }

  /// get all regular wallets
  Future<List<DBWallet>> getRegularWallets() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'wallet_type = ?',
      whereArgs: ['regular'],
    );

    return maps.map((e) => DBWallet.fromMap(e)).toList();
  }

  /// get all card wallets
  Future<List<DBWallet>> getCardWallets() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'wallet_type = ?',
      whereArgs: ['card'],
    );

    return maps.map((e) => DBWallet.fromMap(e)).toList();
  }

  // get wallet by chainId and address
  Future<DBWallet> getWallet(String address) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'address = ?',
      whereArgs: [address],
    );

    return DBWallet.fromMap(maps.first);
  }

  /// create a new wallet
  Future<void> create(DBWallet wallet) async {
    await db.insert(
      name,
      {
        'wallet_type': wallet.type,
        'name': wallet.name,
        'address': wallet.address,
        'balance': wallet.balance,
        'wallet': wallet.wallet,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// update wallet name using the wallet id
  Future<void> updateName(int id, String name) async {
    await db.update(
      this.name,
      {
        'name': name,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// update wallet name using the wallet address
  Future<void> updateNameByAddress(String address, String name) async {
    await db.update(
      this.name,
      {
        'name': name,
      },
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  /// update raw wallet using address
  Future<void> updateRawWallet(String address, String wallet) async {
    await db.update(
      name,
      {
        'wallet': wallet,
      },
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  /// delete wallet by id
  Future<void> delete(int id) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
