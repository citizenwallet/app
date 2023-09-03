import 'dart:io';

import 'package:citizenwallet/services/db/contacts.dart';
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

  Database? _db;
  late ContactTable contacts;
  late VouchersTable vouchers;

// open a database, create tables and migrate data
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        // instantiate a contacts table
        contacts = ContactTable(db);

        // instantiate a vouchers table
        vouchers = VouchersTable(db);
      },
      onCreate: (db, version) async {
        // migrate data
        await contacts.create(db);

        // migrate data
        await vouchers.create(db);

        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // migrate data
        await contacts.migrate(db, oldVersion, newVersion);

        // migrate data
        await vouchers.migrate(db, oldVersion, newVersion);

        return;
      },
      version: 5,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }

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
      _db!.close();
    }

    final path =
        kIsWeb ? '$name.db' : join(await getDatabasesPath(), '$name.db');
    _db = await openDB(path);
  }

  // reset db
  Future<void> resetDB() async {
    if (_db == null) {
      return;
    }

    final path = _db!.path;
    await _db!.close();
    await deleteDatabase(path);
    _db = await openDB(path);
  }

  // delete db
  Future<void> deleteDB() async {
    if (_db == null) {
      return;
    }

    final path = _db!.path;
    await _db!.close();
    await deleteDatabase(path);
  }

  // get db size in bytes
  Future<int> getDBSize() async {
    if (_db == null) {
      return 0;
    }

    final path = _db!.path;
    final file = File(path);
    return file.length();
  }
}
