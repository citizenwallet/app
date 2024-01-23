import 'dart:async';
import 'dart:io' as io;
import 'package:googleapis/drive/v3.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:citizenwallet/services/backup/backup.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

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

  @override
  init(BackupConfigInterface config) async {
    final androidConfig = config as AndroidConfig;

    _driveApi = DriveApi(androidConfig.client);

    _googleSignIn = GoogleSignIn(scopes: scopes);

    await _googleSignIn.signIn();

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

    // if a backup exists, call update
    if (fileId != null) {
      await _driveApi.files.update(
        fileToUpload,
        fileId,
        uploadMedia: Media(file.openRead(), file.lengthSync()),
      );
    } else {
      // if it does not exist, set path for file and call create
      await _driveApi.files.create(
        fileToUpload,
        uploadMedia: Media(file.openRead(), file.lengthSync()),
      );
    }
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
    // 2. get drive file
    final Media driveFile = await _driveApi.files.get(
      fileId,
      downloadOptions: DownloadOptions.fullMedia,
    ) as Media;
    // 3. read all the data from the stream from Google Drive
    final bytes = await driveFile.stream.expand((x) => x).toList();
    // 4. create a file at the provided path and write the bytes to it
    final file = io.File(path);
    await file.writeAsBytes(bytes);
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
