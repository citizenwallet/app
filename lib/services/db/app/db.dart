import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/app/communities.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class AppDBService extends DBService {
  static final AppDBService _instance = AppDBService._internal();

  factory AppDBService() {
    return _instance;
  }

  AppDBService._internal();

  late CommunityTable communities;

  @override
  Future<Database> openDB(String path) async {
    debugPrint('📂 Opening database at: $path');
    bool isNewDatabase = false;

    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        debugPrint('⚙️ Configuring database...');
        communities = CommunityTable(db);
      },
      onCreate: (db, version) async {
        debugPrint('🆕 Creating new database (version $version)...');
        await communities.create(db);
        isNewDatabase = true; // Flag that this is a new database
        debugPrint('✅ Database creation complete');
        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        debugPrint(
            '⬆️ Upgrading database from v$oldVersion to v$newVersion...');
        await communities.migrate(db, oldVersion, newVersion);
        debugPrint('✅ Database upgrade complete');
        return;
      },
      version: 3,
    );

    debugPrint('🔓 Opening database file...');
    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );
    debugPrint('✅ Database file opened (isNew: $isNewDatabase)');

    // Seed AFTER the database is fully opened and onCreate transaction is complete
    if (isNewDatabase) {
      debugPrint('🌱 New database detected, starting seed...');
      try {
        await communities.seed(db);
        debugPrint('✅ Seeding complete');
      } catch (e, s) {
        debugPrint('❌ Seeding failed: $e');
        debugPrintStack(stackTrace: s);
        // Don't rethrow - allow app to continue even if seeding fails
      }
    } else {
      debugPrint('📊 Existing database, skipping seed');
    }

    debugPrint('✅ Database ready');
    return db;
  }
}
