import 'package:citizenwallet/services/db/db.dart';
import 'package:sqflite_common/sqflite.dart';

class DBContact {
  final String account;
  final String username;
  final String name;
  final String description;
  final String image;
  final String imageMedium;
  final String imageSmall;
  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  DBContact({
    required this.account,
    required this.username,
    required this.name,
    required this.description,
    required this.image,
    required this.imageMedium,
    required this.imageSmall,
  });

  DBContact.read({
    required this.account,
    required this.username,
    required this.name,
    required this.description,
    required this.image,
    required this.imageMedium,
    required this.imageSmall,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'account': account,
      'username': username,
      'name': name,
      'description': description,
      'image': image,
      'imageMedium': imageMedium,
      'imageSmall': imageSmall,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt':
          DateTime.now().toIso8601String(), // update the updatedAt time
    };
  }

  factory DBContact.fromMap(Map<String, dynamic> map) {
    return DBContact.read(
      account: map['account'],
      username: map['username'],
      name: map['name'],
      description: map['description'],
      image: map['image'],
      imageMedium: map['imageMedium'],
      imageSmall: map['imageSmall'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class ContactTable extends DBTable {
  ContactTable(super.db);

  // The name of the table
  @override
  String get name => 't_contact';

  // The SQL query to create the table
  @override
  String get createQuery => '''
    CREATE TABLE $name (
      account TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      image TEXT NOT NULL,
      imageMedium TEXT NOT NULL,
      imageSmall TEXT NOT NULL,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    )
  ''';

  // Creates the table
  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    await db.execute('''
        CREATE INDEX idx_${name}_username ON $name (username)
      ''');
  }

  // Migrates the table
  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {}

  // Inserts a new contact into the table
  Future<void> upsert(DBContact contact) async {
    await db.insert(
      name,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Updates an existing contact in the table
  Future<void> update(DBContact contact) async {
    await db.update(
      name,
      contact.toMap(),
      where: 'account = ?',
      whereArgs: [contact.account],
    );
  }

  // Deletes a contact from the table by its account property
  Future<void> delete(String account) async {
    await db.delete(
      name,
      where: 'account = ?',
      whereArgs: [account],
    );
  }

  // Returns a list of all contacts in the table, ordered by their updatedAt property in descending order
  Future<List<DBContact>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return DBContact.fromMap(maps[i]);
    });
  }

  // Returns a list of contacts from the table by their username property
  Future<List<DBContact>> search(String value) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'username LIKE ? OR name LIKE ?',
      whereArgs: ['%$value%', '%$value%'],
      orderBy: 'updatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return DBContact.fromMap(maps[i]);
    });
  }

  // Returns a single contact from the table by its account property
  Future<DBContact?> get(String account) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'account = ?',
      whereArgs: [account],
    );

    if (maps.isEmpty) {
      return null;
    }

    return DBContact.fromMap(maps.first);
  }

  // Returns a single contact from the table by its username property
  Future<DBContact?> getByUsername(String username) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isEmpty) {
      return null;
    }

    return DBContact.fromMap(maps.first);
  }
}
