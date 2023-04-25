import 'dart:typed_data';

import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:web3dart/crypto.dart';

// class representing a wallet from WalletTable
class DBWallet {
  final String type;
  final String name;
  final String address;
  final Uint8List publicKey;
  final int balance;
  final String wallet;
  final bool locked;

  DBWallet({
    required this.type,
    required this.name,
    required this.address,
    required this.publicKey,
    required this.balance,
    required this.wallet,
    this.locked = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'wallet_type': type,
      'name': name,
      'address': address,
      'public_key': bytesToHex(publicKey, include0x: true),
      'balance': balance,
      'wallet': wallet,
      'locked': locked ? 1 : 0,
    };
  }

  factory DBWallet.fromMap(Map<String, dynamic> map) {
    return DBWallet(
      type: map['wallet_type'],
      name: map['name'],
      address: map['address'],
      publicKey: hexToBytes(map['public_key']),
      balance: map['balance'],
      wallet: map['wallet'],
      locked: map['locked'] == 1,
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
      address TEXT NOT NULL PRIMARY KEY,
      wallet_type TEXT NOT NULL,
      name TEXT NOT NULL,
      public_key TEXT NOT NULL,
      balance INTEGER NOT NULL,
      wallet TEXT NOT NULL,
      locked INTEGER DEFAULT 0
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
        'address': wallet.address,
        'wallet_type': wallet.type,
        'name': wallet.name,
        'public_key': bytesToHex(wallet.publicKey, include0x: true),
        'balance': wallet.balance,
        'wallet': wallet.wallet,
        'locked': wallet.locked ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
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

  // lock wallet by address
  Future<void> lock(String address, String wallet) async {
    await db.update(
      name,
      {
        'locked': 1,
        'wallet': wallet,
      },
      where: 'address = ?',
      whereArgs: [address],
    );
  }

  // unlock wallet by address
  Future<void> unlock(String address, String wallet) async {
    await db.update(
      name,
      {
        'locked': 0,
        'wallet': wallet,
      },
      where: 'address = ?',
      whereArgs: [address],
    );
  }
}
