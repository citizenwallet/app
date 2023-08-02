import 'dart:io';

import 'package:citizenwallet/services/db/contacts.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<void> migrate(Database db, int version) async {}
}

class DBService {
  static final DBService _instance = DBService._internal();

  factory DBService() {
    return _instance;
  }

  DBService._internal();

  Database? _db;
  late ContactTable contacts;

// open a database, create tables and migrate data
  Future<Database> openDB(String path) async {
    final db = await openDatabase(
      path,
      onConfigure: (db) async {
        // instantiate a transactions table
        contacts = ContactTable(db);
      },
      onCreate: (db, version) async {
        // migrate data
        await contacts.migrate(db, version);

        return;
      },
      version: 1,
    );

    return db;
  }

  Future<void> init(String name) async {
    if (kIsWeb) {
      // Change default factory on the web
      databaseFactory = databaseFactoryFfiWeb;
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
