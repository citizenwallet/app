import 'dart:io';
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

abstract class DBService {
  Database? _db;
  late String name;

  String get path => _db!.path;

  // open a database, create tables and migrate data
  Future<Database> openDB(String path);

  Future<void> init(String name) async {
    if (kIsWeb) {
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
    }

    if (_db != null && _db!.isOpen) {
      await _db!.close();
    }

    this.name = '$name.db';
    final dbPath =
        kIsWeb ? this.name : join(await getDatabasesPath(), this.name);

    print('dbPath: $dbPath');
    _db = await openDB(dbPath);
  }

  // reset db
  Future<void> resetDB() async {
    if (_db == null) return;

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
    _db = await openDB(dbPath);
  }

  // delete db
  Future<void> deleteDB() async {
    if (_db == null) return;

    final dbPath = _db!.path;
    await _db!.close();
    await deleteDatabase(dbPath);
  }

  // get db size in bytes
  Future<int> getDBSize() async {
    if (_db == null) return 0;

    final dbPath = _db!.path;
    final file = File(dbPath);
    return file.length();
  }
}

Future<String> getDBPath(String name) async {
  return kIsWeb ? '$name.db' : join(await getDatabasesPath(), '$name.db');
}
