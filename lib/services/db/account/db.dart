import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/account/contacts.dart';
import 'package:citizenwallet/services/db/account/transactions.dart';
import 'package:citizenwallet/services/db/account/vouchers.dart';
import 'package:sqflite/sqflite.dart';

class AccountDBService extends DBService {
  static final AccountDBService _instance = AccountDBService._internal();

  factory AccountDBService() {
    return _instance;
  }

  AccountDBService._internal();

  late ContactTable contacts;
  late VouchersTable vouchers;
  late TransactionsTable transactions;

// open a database, create tables and migrate data
  @override
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
}
