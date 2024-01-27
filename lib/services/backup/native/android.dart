import 'dart:async';
import 'dart:io' as io;
import 'package:citizenwallet/services/backup/native/utils.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import 'package:citizenwallet/services/backup/backup.dart';
import 'package:flutter/foundation.dart';

class AndroidBackupService extends BackupServiceInterface {
  static final AndroidBackupService _instance =
      AndroidBackupService._internal();

  factory AndroidBackupService() {
    return _instance;
  }

  AndroidBackupService._internal();

  static const backupFolder = 'appDataFolder';
  static const scopes = [
    DriveApi.driveFileScope,
    DriveApi.driveAppdataScope,
  ];

  late DriveApi _driveApi;
  late GoogleSignIn _googleSignIn;

  final _credentials = getCredentialsService();

  @override
  init({BackupConfigInterface? config}) async {
    _googleSignIn = GoogleSignIn(
      scopes: scopes,
    );

    final account = await _googleSignIn.signIn();

    if (account == null) {
      throw BackupSignInException();
    }

    final client = await _googleSignIn.authenticatedClient();

    if (client == null) {
      throw BackupSignInException();
    }

    _driveApi = DriveApi(client);

    return account.email;
  }

  @override
  Future<(String?, DateTime?)> backupExists(String name) async {
    final files = await _driveApi.files.list(
      q: 'name = "$name"',
      spaces: backupFolder,
    );

    if (files.files == null) {
      return (null, null);
    }

    File? existingFile;
    for (final file in files.files!) {
      if (file.name == name) {
        existingFile = file;
        break;
      }
    }

    if (existingFile == null) {
      return (null, null);
    }

    return (existingFile.id, existingFile.modifiedTime);
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
    final (fileId, _) = await backupExists(path);

    final file = io.File(path);

    final encryptedFile = await encryptFile(file, _credentials);

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
    final (fileId, _) = await backupExists(name);
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

    await decryptFile(encryptedFile, _credentials);

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
    final (fileId, _) = await backupExists(name);
    if (fileId == null) {
      throw BackupNotFoundException();
    }

    await _driveApi.files.delete(
      fileId,
    );

    return;
  }
}
