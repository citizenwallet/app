import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';

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
      chainId INTEGER NOT NULL,
      balance INTEGER NOT NULL,
      wallet TEXT NOT NULL,
      UNIQUE(address, chainId)
    )
  ''';

  @override
  Future<void> migrate(Database db, int version) async {
    if (version == 1) {
      await db.execute(createQuery);
    }
  }

  /// get all regular wallets
  Future<List<Map<String, dynamic>>> getRegularWallets() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'wallet_type = ?',
      whereArgs: ['regular'],
    );

    return maps;
  }

  /// get all card wallets
  Future<List<Map<String, dynamic>>> getCardWallets() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'wallet_type = ?',
      whereArgs: ['card'],
    );

    return maps;
  }

  // get wallet by chainId and address
  Future<Map<String, dynamic>> getWallet(int chainId, String address) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'chainId = ? AND address = ?',
      whereArgs: [chainId, address],
    );

    return maps.first;
  }

  /// create a new wallet
  Future<void> create(String type, String name, String address, int chainId,
      int balance, String wallet) async {
    await db.insert(
      this.name,
      {
        'wallet_type': type,
        'name': name,
        'address': address,
        'chainId': chainId,
        'balance': balance,
        'wallet': wallet,
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

  /// delete wallet by id
  Future<void> delete(int id) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
