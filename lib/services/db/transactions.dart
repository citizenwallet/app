import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite_common/sqflite.dart';

// a class representing a transaction in the db
class DBTransaction {
  final String hash;
  final String txHash;
  final int tokenId;
  final DateTime createdAt;
  final String from;
  final String to;
  final int nonce;
  final int value;
  final String data;
  final String status;

  final String contract;

  DBTransaction({
    required this.hash,
    required this.txHash,
    required this.tokenId,
    required this.createdAt,
    required this.from,
    required this.to,
    required this.nonce,
    required this.value,
    required this.data,
    required this.status,
    required this.contract,
  });

  Map<String, dynamic> toMap() {
    return {
      'hash': hash,
      'tx_hash': txHash,
      'token_id': tokenId,
      'created_at': createdAt.toIso8601String(),
      't_from': from,
      't_to': to,
      'nonce': nonce,
      'value': value,
      'data': data,
      'status': status,
      'contract': contract,
    };
  }

  factory DBTransaction.fromMap(Map<String, dynamic> map) {
    return DBTransaction(
      hash: map['hash'],
      txHash: map['tx_hash'],
      tokenId: map['token_id'],
      createdAt: DateTime.parse(map['created_at']),
      from: map['t_from'],
      to: map['t_to'],
      nonce: map['nonce'],
      value: map['value'],
      data: map['data'],
      status: map['status'],
      contract: map['contract'],
    );
  }
}

class TransactionsTable extends DBTable {
  TransactionsTable(Database db) : super(db);

  @override
  String get name => 't_transaction';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      hash TEXT PRIMARY KEY,
      tx_hash TEXT NOT NULL,
      token_id INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      t_from TEXT NOT NULL,
      t_to TEXT NOT NULL,
      nonce INTEGER NOT NULL,
      value INTEGER NOT NULL,
      data TEXT NOT NULL,
      status TEXT NOT NULL,
      contract TEXT NOT NULL
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_contract_token_id ON $name (contract, token_id)
      ''');

    await db.execute('''
        CREATE INDEX idx_${name}_tx_hash ON $name (tx_hash)
      ''');

    await db.execute('''
        CREATE INDEX idx_${name}_date_from_contract_token_id_t_from_simple ON $name (created_at, contract, token_id, t_from);
      ''');

    await db.execute('''
        CREATE INDEX idx_${name}_date_from_contract_token_id_t_to_simple ON $name (created_at, contract, token_id, t_to);
      ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrations = {
      6: [
        createQuery,
        '''
          CREATE INDEX idx_${name}_contract_token_id ON $name (contract, token_id)
        ''',
        '''
          CREATE INDEX idx_${name}_tx_hash ON $name (tx_hash)
        ''',
        '''
          CREATE INDEX idx_${name}_date_from_contract_token_id_t_from_simple ON $name (created_at, contract, token_id, t_from);
        ''',
        '''
          CREATE INDEX idx_${name}_date_from_contract_token_id_t_to_simple ON $name (created_at, contract, token_id, t_to);
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

  // CRUD operations on transactions

  // insert single transaction
  Future<void> insert(DBTransaction transaction) async {
    await db.insert(
      name,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // insert multiple transactions
  Future<void> insertAll(List<DBTransaction> transactions) async {
    final batch = db.batch();

    for (final transaction in transactions) {
      batch.insert(
        name,
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // get previous transactions
  Future<List<DBTransaction>> getPreviousTransactions(
    DateTime createdAt,
    String contract,
    int tokenId,
    String address, {
    int limit = 10,
    int offset = 0,
  }) async {
    final formattedDate = createdAt.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $name
      WHERE created_at <= ? AND contract = ? AND token_id = ? AND t_from = ?
      UNION ALL
      SELECT * FROM $name
      WHERE created_at <= ? AND contract = ? AND token_id = ? AND t_to = ?
      ORDER BY created_at DESC
      LIMIT ?
      OFFSET ?
    ''', [
      formattedDate,
      contract,
      tokenId,
      address,
      formattedDate,
      contract,
      tokenId,
      address,
      limit,
      offset,
    ]);

    return List.generate(maps.length, (i) {
      return DBTransaction.fromMap(maps[i]);
    });
  }

  // get new transactions
  Future<List<DBTransaction>> getNewTransactions(
    DateTime createdAt,
    String contract,
    int tokenId,
    String address, {
    int limit = 10,
    int offset = 0,
  }) async {
    final formattedDate = createdAt.toIso8601String();

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM $name
      WHERE created_at > ? AND contract = ? AND token_id = ? AND t_from = ?
      UNION ALL
      SELECT * FROM $name
      WHERE created_at > ? AND contract = ? AND token_id = ? AND t_to = ?
      ORDER BY created_at DESC
      LIMIT ?
      OFFSET ?
    ''', [
      formattedDate,
      contract,
      tokenId,
      address,
      formattedDate,
      contract,
      tokenId,
      address,
      limit,
      offset,
    ]);

    return List.generate(maps.length, (i) {
      return DBTransaction.fromMap(maps[i]);
    });
  }
}
