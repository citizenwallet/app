import 'dart:convert';
import 'package:credential_manager/credential_manager.dart';

import 'package:citizenwallet/services/credentials/backup.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pinCodeCheckKey = 'cw__pinCodeCheck__';
const pinCodeKey = 'cw__pinCode__';

class EncryptedData {
  final Uint8List data;
  final int nonceLength;
  final int macLength;

  EncryptedData({
    required this.data,
    required this.nonceLength,
    required this.macLength,
  });

  EncryptedData.fromJson(Map<String, dynamic> json)
      : data = base64.decode(json['data']),
        nonceLength = json['nonceLength'],
        macLength = json['macLength'];

  Map<String, dynamic> toJson() => {
        'data': base64.encode(data),
        'nonceLength': nonceLength,
        'macLength': macLength,
      };
}

/// AndroidCredentialsService implements an CredentialsServiceInterface for Android
class AndroidCredentialsService extends CredentialsServiceInterface {
  static final AndroidCredentialsService _instance =
      AndroidCredentialsService._internal();
  factory AndroidCredentialsService() => _instance;
  AndroidCredentialsService._internal();

  late CredentialManager _credentials;
  late SharedPreferences _preferences;

  @override
  Future init(CredentialsOptionsInterface options) async {
    _credentials = CredentialManager();

    if (_credentials.isSupportedPlatform) {
      // if supported
      await _credentials.init(preferImmediatelyAvailableCredentials: true);
    }

    _preferences = await SharedPreferences.getInstance();

    await migrate(super.version);
  }

  @override
  Future<void> migrate(int version) async {
    final int oldVersion =
        int.tryParse(_preferences.getString(versionPrefix) ?? '0') ?? 0;

    if (oldVersion == version) {
      return;
    }

    final migrations = {};

    // run all migrations
    for (var i = oldVersion + 1; i <= version; i++) {
      if (migrations.containsKey(i)) {
        await migrations[i]!();
      }
    }

    // after success, we can update the version
    await _preferences.setString(versionPrefix, version.toString());
  }

  // handle wallet backups
  // use the prefix as a query to find a wallet backup
  // use the prefix + wallet address as a way to query the backup
  // store the json as a b64 encoded string, reason: we store the name of the wallet
  // key = wb_$wallet_address, value = $name|$privateKey

  // get all wallet backups
  @override
  Future<List<BackupWallet>> getAllWalletBackups() async {
    return [];
  }

  // set wallet backup
  @override
  Future<void> setWalletBackup(BackupWallet backup) async {
    await _credentials.savePasswordCredentials(PasswordCredential(
        username: '${backup.address}|${backup.alias}', password: backup.value));
  }

  // get wallet backup
  @override
  Future<BackupWallet?> getWalletBackup(String address, String alias) async {
    PasswordCredential credential = await _credentials.getPasswordCredentials();

    if (credential.username == null || credential.password == null) {
      return null;
    }

    final [cralias, craddress] = credential.username!.split('|');

    if (craddress != address || cralias != alias) {
      return null;
    }

    final privateKey = credential.password;

    if (privateKey == null) {
      return null;
    }

    final BackupWallet backup = BackupWallet.fromJson({
      'address': craddress,
      'privateKey': privateKey,
      'name': 'Wallet',
      'alias': cralias,
    });

    return backup;
  }

  // get wallet backups for alias
  @override
  Future<List<BackupWallet>> getWalletBackupsForAlias(String alias) async {
    return [];
  }

  // delete wallet backup
  @override
  Future<void> deleteWalletBackup(String address, String alias) async {}

  // delete all wallet backups
  @override
  Future<void> deleteWalletBackups() async {}
}
