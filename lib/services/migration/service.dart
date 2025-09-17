import 'dart:io';
import 'dart:math';
import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class MigrationService {
  static final MigrationService _instance = MigrationService._internal();
  factory MigrationService() => _instance;
  MigrationService._internal();

  EthPrivateKey generateMigrationKey() {
    final random = Random.secure();
    final privateKey = EthPrivateKey.createRandom(random);
    return privateKey;
  }

  // Encrypts the database file using the provided private key
  Future<File> encryptDatabase(String dbPath, EthPrivateKey privateKey) async {
    try {
      final dbFile = File(dbPath);
      if (!dbFile.existsSync()) {
        throw Exception('Database file not found: $dbPath');
      }

      final dbBytes = await dbFile.readAsBytes();

      final keyBytes = privateKey.privateKey;
      final encryptKey = keyBytes.length == 33 ? keyBytes.sublist(1) : keyBytes;

      final encrypt = Encrypt(encryptKey);

      final encryptedBytes = await encrypt.encrypt(dbBytes);

      final encryptedFile = File('${dbPath}.encrypted');
      await encryptedFile.writeAsBytes(encryptedBytes);

      return encryptedFile;
    } catch (e) {
      rethrow;
    }
  }

  //Uploads the encrypted database using the existing backup service
  Future<void> uploadEncryptedDatabase(
    File encryptedFile,
    String fileName,
  ) async {
    try {
      final backupService = getBackupService();

      final username = await backupService.init();

      await backupService.upload(encryptedFile.path, fileName);

      await encryptedFile.delete();
    } catch (e) {
      debugPrint('Error uploading database: $e');
      rethrow;
    }
  }

  // Launches the new app with the migration deep link
  Future<void> launchNewApp(String privateKeyHex) async {
    try {
      final deepLink = 'citizenwallet2://migrate?key=$privateKeyHex';
      final uri = Uri.parse(deepLink);
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        // Use url_launcher to open the external app
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch new app: $deepLink');
      }
    } catch (e) {
      debugPrint('Error launching new app: $e');
      rethrow;
    }
  }

  /// Performs the complete migration process
  Future<void> performMigration() async {
    try {
      final privateKey = generateMigrationKey();
      final privateKeyHex = bytesToHex(privateKey.privateKey);
      final address = privateKey.address.hexEip55;

      final accountsDB = AccountBackupDBService();
      await accountsDB.init('accounts');
      final dbPath = accountsDB.path;

      final dbFile = File(dbPath);
      if (dbFile.existsSync()) {
        final dbSize = await dbFile.length();
      } else {}

      final encryptedFile = await encryptDatabase(dbPath, privateKey);
      final encryptedSize = await encryptedFile.length();

      final fileName = '${address}.db';

      await uploadEncryptedDatabase(encryptedFile, fileName);

      await launchNewApp(privateKeyHex);
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      rethrow;
    }
  }
}
