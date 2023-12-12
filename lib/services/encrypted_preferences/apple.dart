import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:collection/collection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AppleEncryptedPreferencesOptions
class AppleEncryptedPreferencesOptions implements EncryptedPreferencesOptions {
  final String groupId;

  AppleEncryptedPreferencesOptions({
    required this.groupId,
  });
}

/// AppleEncryptedPreferencesService implements an EncryptedPreferencesService for iOS and macOS
class AppleEncryptedPreferencesService extends EncryptedPreferencesService {
  static final AppleEncryptedPreferencesService _instance =
      AppleEncryptedPreferencesService._internal();
  factory AppleEncryptedPreferencesService() => _instance;
  AppleEncryptedPreferencesService._internal();

  IOSOptions _getIOSOptions(String groupId) => IOSOptions(
        groupId: groupId,
        accessibility: KeychainAccessibility.unlocked,
        synchronizable: true,
      );

  MacOsOptions _getMacOsOptions(String groupId) => MacOsOptions(
        groupId: groupId,
        accessibility: KeychainAccessibility.unlocked,
        synchronizable: true,
      );

  late FlutterSecureStorage _preferences;

  @override
  Future init(EncryptedPreferencesOptions options) async {
    final appleOptions = options as AppleEncryptedPreferencesOptions;
    _preferences = FlutterSecureStorage(
      iOptions: _getIOSOptions(appleOptions.groupId),
      mOptions: _getMacOsOptions(appleOptions.groupId),
    );

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(await _preferences.read(key: versionPrefix) ?? '0') ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {
      1: () async {
        // coming from the old version, migrate all keys and delete the old ones
        // all or nothing, first write all the new ones, then delete all the old ones
        final allBackups = await getAllWalletBackups();

        for (final backup in allBackups) {
          // await setWalletBackup(backup);
          final saved = await _preferences.containsKey(key: backup.legacyKey2);
          if (saved) {
            await _preferences.delete(key: backup.legacyKey2);
          }

          await _preferences.write(
            key: backup.legacyKey2,
            value: backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // legacy delete
          final saved = await _preferences.containsKey(
            key: backup.legacyKey,
          );
          if (saved) {
            await _preferences.delete(key: backup.legacyKey);
          }
        }
      },
      2: () async {
        final allBackups = await getAllWalletBackups();

        for (final backup in allBackups) {
          final saved = await _preferences.containsKey(key: backup.key);
          if (saved) {
            await _preferences.delete(key: backup.key);
          }

          await _preferences.write(
            key: backup.key,
            value: backup.value,
          );
        }

        // delete all old keys
        for (final backup in allBackups) {
          // delete legacy keys
          final saved = await _preferences.containsKey(
            key: backup.legacyKey2,
          );

          if (saved) {
            await _preferences.delete(
              key: backup.legacyKey2,
            );
          }
        }
      },
      3: () async {
        final allBackups = await getAllWalletBackups();

        final toDelete = <String>[];

        for (final backup in allBackups) {
          bool saved = await _preferences.containsKey(key: backup.key);
          if (!saved) {
            continue;
          }

          final account = await getLegacyAccountAddress(backup);
          if (account == null) {
            continue;
          }

          final newBackup = BackupWallet(
            address: account.hexEip55,
            privateKey: backup.privateKey,
            name: backup.name,
            alias: backup.alias,
          );

          await _preferences.write(
            key: newBackup.key,
            value: newBackup.value,
          );

          toDelete.add(backup.key);
        }

        // delete all old keys
        for (final backup in allBackups) {
          if (!toDelete.contains(backup.key)) {
            continue;
          }

          // delete legacy keys
          final saved = await _preferences.containsKey(
            key: backup.key,
          );

          if (saved) {
            await _preferences.delete(
              key: backup.key,
            );
          }
        }
      },
    };

    // run all migrations
    for (var i = oldVersion + 1; i <= version; i++) {
      if (migrations.containsKey(i)) {
        await migrations[i]!();
      }
    }

    // after success, we can update the version
    await _preferences.write(key: versionPrefix, value: version.toString());
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    final allValues = await _preferences.readAll();
    final keys = allValues.keys.where((key) => key.startsWith(backupPrefix));

    final List<BackupWallet> backups = [];

    for (final k in keys) {
      final parsed = allValues[k]!.split('|');
      if (parsed.length < 2) {
        // invalid backup, consider cleaning up in the future
        continue;
      }

      if (parsed.length == 3) {
        backups.add(BackupWallet(
          address: k.replaceFirst(backupPrefix, ''),
          privateKey: parsed[1],
          name: parsed[0],
          alias: parsed[2],
        ));
        continue;
      }

      if (parsed.length == 4) {
        backups.add(BackupWallet(
          name: parsed[0],
          address: parsed[1],
          privateKey: parsed[2],
          alias: parsed[3],
        ));
        continue;
      }

      backups.add(BackupWallet(
        address: k.replaceFirst(backupPrefix, ''),
        privateKey: parsed[1],
        name: parsed[0],
        alias: 'app',
      ));
    }

    backups.sort((a, b) => a.name.compareTo(b.name));

    return backups;
  }

  // set wallet backup
  @override
  Future<void> setWalletBackup(BackupWallet backup) async {
    final saved = await _preferences.containsKey(key: backup.key);
    if (saved) {
      await _preferences.delete(key: backup.key);
    }

    await _preferences.write(
      key: backup.key,
      value: backup.value,
    );
  }

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address, String alias) async {
    final wallets = await getAllWalletBackups();

    return wallets.firstWhereOrNull(
      (w) => w.address == address && w.alias == alias,
    );
  }

  // get wallet backups for alias
  @override
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias) async {
    final wallets = await getAllWalletBackups();

    return wallets.where((w) => w.alias == alias).toList();
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address, String alias) async {
    final wallets = await getAllWalletBackups();

    final wallet = wallets.firstWhereOrNull(
      (w) => w.address == address && w.alias == alias,
    );

    if (wallet == null) {
      return;
    }

    await _preferences.delete(key: wallet.key);
  }

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {
    await _preferences.deleteAll();
  }
}
