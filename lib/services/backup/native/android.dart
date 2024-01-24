import 'dart:async';
import 'dart:io' as io;
import 'package:citizenwallet/utils/encrypt.dart';
import 'package:credential_manager/credential_manager.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:citizenwallet/services/backup/backup.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';

const credentialStorageKey = 'app@cw';

class AndroidConfig extends BackupConfigInterface {
  final Client client;
  final String oauthClientId;

  AndroidConfig({
    required this.client,
    required this.oauthClientId,
  });
}

class AndroidBackupService extends BackupServiceInterface {
  static const backupFolder = 'appDataFolder';
  static const scopes = [
    'https://www.googleapis.com/auth/drive.file',
    DriveApi.driveAppdataScope,
  ];

  late DriveApi _driveApi;
  late GoogleSignIn _googleSignIn;

  late CredentialManager _credentials;
  late Encrypt _encrypt;

  @override
  init(BackupConfigInterface config) async {
    final androidConfig = config as AndroidConfig;

    _driveApi = DriveApi(androidConfig.client);

    _googleSignIn = GoogleSignIn(scopes: scopes);

    await _googleSignIn.signIn();

    _credentials = CredentialManager();

    if (_credentials.isSupportedPlatform) {
      throw BackupNotSupportedException();
    }

    // if supported
    await _credentials.init(preferImmediatelyAvailableCredentials: true);

    try {
      // check if there is an encryption key available
      final credential = await _credentials.getPasswordCredentials();

      if (credential.password == null) {
        throw BackupSourceMissingException();
      }

      _encrypt = Encrypt(hexToBytes(credential.password!));
    } catch (e) {
      // if not, create one
      // generate a random key
      final key = generateKey(32);

      await _credentials.savePasswordCredentials(
        PasswordCredential(
          username: credentialStorageKey,
          password: bytesToHex(key),
        ),
      );

      _encrypt = Encrypt(key);
    }

    return;
  }

  @override
  Future<String?> backupExists(String name) async {
    final files = await _driveApi.files.list(
      q: 'name = "$name"',
      spaces: backupFolder,
    );

    if (files.files == null) {
      return null;
    }

    File? existingFile;
    for (final file in files.files!) {
      if (file.name == name) {
        existingFile = file;
        break;
      }
    }

    if (existingFile == null) {
      return null;
    }

    return existingFile.id;
  }

  @override
  Future<void> upload(String path, String name) async {
    final user = await _googleSignIn.signInSilently();
    if (user == null) {
      await _googleSignIn.signIn();
    }

    // 2. instanciate File(this is not from io, but from googleapis
    final fileToUpload = File();
    // 3. set file name for file to upload
    fileToUpload.name = name;
    // 4. check if the backup file is already exist
    final fileId = await backupExists(path);

    final file = io.File(path);
    if (!file.existsSync()) {
      throw BackupSourceMissingException();
    }

    final fileBytes = await file.readAsBytes();

    final encryptedBytes = await _encrypt.encrypt(fileBytes);

    final encryptedFile = io.File('$path.encrypted');
    await encryptedFile.writeAsBytes(encryptedBytes);

    // if a backup exists, call update
    if (fileId != null) {
      await _driveApi.files.update(
        fileToUpload,
        fileId,
        uploadMedia: Media(
          encryptedFile.openRead(),
          encryptedFile.lengthSync(),
        ),
      );
    } else {
      // if it does not exist, set path for file and call create
      await _driveApi.files.create(
        fileToUpload,
        uploadMedia: Media(
          encryptedFile.openRead(),
          encryptedFile.lengthSync(),
        ),
      );
    }

    // delete local encrypted file
    await encryptedFile.delete();
    if (kDebugMode) {
      print('cloud : uploaded');
    }
  }

  @override
  Future<void> download(String name, String path) async {
    final user = await _googleSignIn.signInSilently();
    if (user == null) {
      await _googleSignIn.signIn();
    }

    // check backup before download
    final fileId = await backupExists(name);
    if (fileId == null) {
      throw BackupNotFoundException();
    }
    // get drive file
    final Media driveFile = await _driveApi.files.get(
      fileId,
      downloadOptions: DownloadOptions.fullMedia,
    ) as Media;

    // read all the data from the stream from Google Drive
    final bytes = await driveFile.stream.expand((x) => x).toList();

    // create a file at the provided path and write the bytes to it
    final encryptedFile = io.File('$path.encrypted');
    await encryptedFile.writeAsBytes(bytes);

    // decrypt the file
    final encryptedBytes = await encryptedFile.readAsBytes();
    final decryptedBytes = await _encrypt.decrypt(encryptedBytes);

    // create the final file
    final file = io.File(path);
    await file.writeAsBytes(decryptedBytes);

    // delete local encrypted file
    await encryptedFile.delete();
  }

  @override
  Future<void> delete(String name) async {
    final user = await _googleSignIn.signInSilently();
    if (user == null) {
      await _googleSignIn.signIn();
    }

    // check backup before download
    final fileId = await backupExists(name);
    if (fileId == null) {
      throw BackupNotFoundException();
    }

    await _driveApi.files.delete(
      fileId,
    );

    return;
  }
}
