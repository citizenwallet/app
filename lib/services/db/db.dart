import 'dart:io';

import 'package:citizenwallet/services/db/accounts.dart';
import 'package:citizenwallet/services/db/contacts.dart';
import 'package:citizenwallet/services/db/transactions.dart';
import 'package:citizenwallet/services/db/vouchers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite_common/sqflite.dart';

abstract class DBTable {
  final Database _db;

  DBTable(this._db);

  Database get db => _db;

  String get name => 'table';
  String get createQuery => '''
    CREATE TABLE $name (
      id INTEGER PRIMARY KEY
    )
  ''';

  Future<void> create(Database db);

  Future<void> migrate(Database db, int oldVersion, int newVersion);
}

class DBService {
  static final DBService _instance = DBService._internal();

  factory DBService() {
    return _instance;
  }

  DBService._internal();

  Database? _db; // TODO: move to absract

  late String name; // TODO: move to absract
  String get path { 
    return _db!.path;
  }

  late ContactTable contacts;
  late VouchersTable vouchers;
  late TransactionsTable transactions;

// open a database, create tables and migrate data
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        // instantiate a contacts table
        contacts = ContactTable(db);

        // instantiate a vouchers table
        vouchers = VouchersTable(db);

        // instantiate a transactions table
        transactions = TransactionsTable(db);
      },
      onCreate: (db, version) async {
        // create tables
        await contacts.create(db);

        await vouchers.create(db);

        await transactions.create(db);

        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // migrate data
        await contacts.migrate(db, oldVersion, newVersion);

        await vouchers.migrate(db, oldVersion, newVersion);

        await transactions.migrate(db, oldVersion, newVersion);

        return;
      },
      version: 8,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }


  // TODO: move to absract
  Future<void> init(String name) async {
    if (kIsWeb) {
      // Change default factory on the web
      final swOptions = SqfliteFfiWebOptions(
        sqlite3WasmUri: Uri.parse('sqlite3.wasm'),
        sharedWorkerUri: Uri.parse('sqflite_sw.js'),
        indexedDbName: '$name.db',
      );

      final webContext = defaultTargetPlatform == TargetPlatform.android
          ? await sqfliteFfiWebLoadSqlite3Wasm(swOptions)
          : await sqfliteFfiWebStartSharedWorker(swOptions);

      databaseFactory =
          createDatabaseFactoryFfiWeb(options: webContext.options);
      // databaseFactory = databaseFactoryFfiWeb;
      // path = 'my_web_web.db';
    }

    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }

    this.name = '$name.db';
    final dbPath =
        kIsWeb ? this.name : join(await getDatabasesPath(), this.name);
    _db = await openDB(dbPath);
  }

  // reset db
  // TODO: move to absract
  Future<void> resetDB() async {
    if (_db == null) {
      return;
    }

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
    _db = await openDB(dbPath);
  }

  // delete db
  // TODO: move to absract
  Future<void> deleteDB() async {
    if (_db == null) {
      return;
    }

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
  }

  // get db size in bytes
  // TODO: move to absract
  Future<int> getDBSize() async {
    if (_db == null) {
      return 0;
    }

    final dbPath = _db!.path;
    final file = File(dbPath);
    return file.length();
  }
}

class AccountsDBService {
  static final AccountsDBService _instance = AccountsDBService._internal();

  factory AccountsDBService() {
    return _instance;
  }

  factory AccountsDBService.newInstance() {
    return AccountsDBService._internal();
  }

  AccountsDBService._internal();

  Database? _db;

  late String name;
  String get path {
    return _db!.path;
  }

  late AccountsTable accounts;

// open a database, create tables and migrate data
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        // instantiate a accounts table
        accounts = AccountsTable(db);
      },
      onCreate: (db, version) async {
        // create tables
        await accounts.create(db);

        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // migrate data
        await accounts.migrate(db, oldVersion, newVersion);

        return;
      },
      version: 1,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }

  // TODO: move to absract
  Future<void> init(String name) async {
    if (kIsWeb) {
      // Change default factory on the web
      final swOptions = SqfliteFfiWebOptions(
        sqlite3WasmUri: Uri.parse('sqlite3.wasm'),
        sharedWorkerUri: Uri.parse('sqflite_sw.js'),
        indexedDbName: '$name.db',
      );

      final webContext = defaultTargetPlatform == TargetPlatform.android
          ? await sqfliteFfiWebLoadSqlite3Wasm(swOptions)
          : await sqfliteFfiWebStartSharedWorker(swOptions);

      databaseFactory =
          createDatabaseFactoryFfiWeb(options: webContext.options);
      // databaseFactory = databaseFactoryFfiWeb;
      // path = 'my_web_web.db';
    }

    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }

    this.name = '$name.db';
    final dbPath =
        kIsWeb ? this.name : join(await getDatabasesPath(), this.name);
    _db = await openDB(dbPath);
  }

  Future<void> reInit() async {
    if (_db == null || !_db!.isOpen) {
      throw Exception('DB not initialized');
    }

    await _db!.close();

    final dbPath = kIsWeb ? name : join(await getDatabasesPath(), name);

    _db = await openDB(dbPath);
  }

  // reset db
  Future<void> resetDB() async {
    if (_db == null) {
      return;
    }

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
    _db = await openDB(dbPath);
  }

  // delete db
  Future<void> deleteDB() async {
    if (_db == null) {
      return;
    }

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
  }

  // get db size in bytes
  Future<int> getDBSize() async {
    if (_db == null) {
      return 0;
    }

    final dbPath = _db!.path;
    final file = File(dbPath);
    return file.length();
  }
}

Future<String> getDBPath(String name) async {
  return kIsWeb ? '$name.db' : join(await getDatabasesPath(), '$name.db');
}
