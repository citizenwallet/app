import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';

// a class representing a transaction in the db
class DBTransaction {
  final String id;
  final int chainId;
  final String from;
  final String to;
  final String amount;
  final DateTime date;

  DBTransaction({
    required this.id,
    this.chainId = 0,
    this.from = '0x',
    this.to = '0x',
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chain_id': chainId,
      't_from': from,
      't_to': to,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
    };
  }

  factory DBTransaction.fromMap(Map<String, dynamic> map) {
    return DBTransaction(
      id: map['id'],
      chainId: map['chain_id'],
      from: map['t_from'],
      to: map['t_to'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}

class TransactionTable extends DBTable {
  TransactionTable(Database db) : super(db);

  @override
  String get name => 't_transaction';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      id TEXT PRIMARY KEY,
      chain_id INTEGER NOT NULL,
      t_from TEXT NOT NULL,
      t_to TEXT NOT NULL,
      amount TEXT NOT NULL,
      date INTEGER NOT NULL
    )
  ''';

  @override
  Future<void> create(Database db, int version) async {
    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_chain_id_from ON $name (chain_id, t_from)
      ''');
  }

  @override
  Future<void> migrate(Database db, int version) async {
    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_chain_id_from ON $name (chain_id, t_from)
      ''');
  }

  // CRUD methods for transactions
  Future<void> insert(DBTransaction transaction) async {
    await db.insert(
      name,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // get all transactions for a given chain and from address
  Future<List<DBTransaction>> getAll(int chainId, String from) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'chain_id = ? AND t_from = ?',
      whereArgs: [chainId, from],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return DBTransaction.fromMap(maps[i]);
    });
  }

  Future<void> delete(String id) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // update transaction
  Future<void> update(DBTransaction transaction) async {
    await db.update(
      name,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }
}
