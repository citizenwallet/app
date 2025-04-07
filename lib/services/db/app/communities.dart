import 'dart:convert';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/legacy.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

Future<List<DBCommunity>> legacyToV4(Database db, String name) async {
  final List<Map<String, dynamic>> maps = await db.query(name);

  final legacyConfigs = List.generate(maps.length, (i) {
    return DBCommunity.fromMap(maps[i]);
  });

  final List<DBCommunity> v4Configs = [];
  for (final legacyConfig in legacyConfigs) {
    if (legacyConfig.version == 4) {
      continue;
    }

    final config =
        Config.fromLegacy(LegacyConfig.fromJson(legacyConfig.config));

    v4Configs.add(DBCommunity.fromConfig(config));
  }

  return v4Configs;
}

class DBCommunity {
  final String alias; // index
  final bool hidden;
  final Map<String, dynamic> config;
  final int version;
  bool online;

  DBCommunity({
    required this.alias,
    required this.config,
    this.hidden = false,
    this.version = 0,
    this.online = true,
  });

  // from Config
  factory DBCommunity.fromConfig(Config config) {
    return DBCommunity(
      alias: config.community.alias,
      config: config.toJson(),
      hidden: config.community.hidden,
      version: config.version,
      online: config.online,
    );
  }

  // process after reading from table
  factory DBCommunity.fromMap(Map<String, dynamic> map) {
    return DBCommunity(
      alias: map['alias'],
      config: jsonDecode(map['config']),
      hidden: map['hidden'] == 1,
      version: map['version'],
      online: map['online'] == 1,
    );
  }

  // process before inserting into table
  Map<String, dynamic> toMap() {
    return {
      'alias': alias,
      'version': version,
      'hidden': hidden ? 1 : 0,
      'online': online ? 1 : 0,
      'config': jsonEncode(config),
    };
  }
}

class CommunityTable extends DBTable {
  CommunityTable(super.db);

  final ConfigService _config = ConfigService();

  // The name of the table
  @override
  String get name => 't_community';

  // The SQL query to create the table
  @override
  String get createQuery => '''
    CREATE TABLE $name (
      alias TEXT PRIMARY KEY,
      hidden INTEGER NOT NULL DEFAULT 0,
      config TEXT NOT NULL,
      version INTEGER NOT NULL DEFAULT 0,
      online INTEGER NOT NULL DEFAULT 1
    )
  ''';

  // Creates the table and an index on the alias column
  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create an index on the alias column
    await db.execute('''
      CREATE INDEX idx_${name}_alias ON $name (alias)
    ''');

    await seed();
  }

  // Migrates the table
  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    final migrations = {
      2: [
        'V4Migration',
      ],
    };

    for (var i = oldVersion + 1; i <= newVersion; i++) {
      final queries = migrations[i];

      if (queries != null) {
        for (final query in queries) {
          try {
            switch (query) {
              case 'V4Migration':
                final updatedConfigs = await legacyToV4(db, name);
                await upsert(updatedConfigs);
                continue;
            }

            await db.execute(query);
          } catch (e, s) {
            debugPrint('$name migration error, index $i: $e');
            debugPrintStack(stackTrace: s);
          }
        }
      }
    }
  }

  Future<void> seed() async {
    final localConfigs = await _config.getLocalConfigs();

    // Check if the table is empty
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $name'));
    if (count != null && count > 0) {
      return; // Table is not empty, skip seeding
    }

    // Prepare batch operation for efficient insertion
    final batch = db.batch();

    for (final config in localConfigs) {
      batch.insert(
        name,
        DBCommunity.fromConfig(config).toMap(),
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> upsert(List<DBCommunity> communities) async {
    // Prepare batch operation for efficient insertion
    final batch = db.batch();

    for (final community in communities) {
      batch.insert(
        name,
        community.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<DBCommunity?> get(String alias) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'alias = ?',
      whereArgs: [alias],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DBCommunity.fromMap(maps.first);
  }

  Future<bool> exists(String alias) async {
    final result = await db.query(
      name,
      columns: ['alias'],
      where: 'alias = ?',
      whereArgs: [alias],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<DBCommunity>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(name);

    return List.generate(maps.length, (i) {
      return DBCommunity.fromMap(maps[i]);
    });
  }

  Future<List<DBCommunity>> getOnline() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'online = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) {
      return DBCommunity.fromMap(maps[i]);
    });
  }

  Future<void> updateOnlineStatus(String alias, bool online) async {
    await db.update(
      name,
      {'online': online ? 1 : 0},
      where: 'alias = ?',
      whereArgs: [alias],
    );
  }
}
