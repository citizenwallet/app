import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:sqflite_common/sqflite.dart';

class AccountBackupDBService extends DBService {
  static final AccountBackupDBService _instance =
      AccountBackupDBService._internal();

  factory AccountBackupDBService() {
    return _instance;
  }

  factory AccountBackupDBService.newInstance() {
    return AccountBackupDBService._internal();
  }

  AccountBackupDBService._internal();

  late AccountsTable accounts;

// open a database, create tables and migrate data
  @override
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
      version: 3,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }
}
