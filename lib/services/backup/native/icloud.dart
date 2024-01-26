import 'dart:async';
import 'dart:io';

import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/backup/native/utils.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:icloud_storage/icloud_storage.dart';

const credentialStorageKey = 'app@cw';

class ICloudConfig extends BackupConfigInterface {
  final String containerId;

  ICloudConfig({
    required this.containerId,
  });
}

class ICloudBackupService extends BackupServiceInterface {
  late String _containerId;

  final CredentialsServiceInterface _credentials = getCredentialsService();

  @override
  init(BackupConfigInterface config) async {
    final icloudConfig = config as ICloudConfig;

    _containerId = icloudConfig.containerId;

    return;
  }

  @override
  Future<(String?, DateTime?)> backupExists(String name) async {
    final files = await ICloudStorage.gather(containerId: _containerId);

    final file =
        files.firstWhereOrNull((element) => element.relativePath == '/$name');
    if (file == null) {
      return (null, null);
    }
    return (file.relativePath, file.contentChangeDate);
  }

  @override
  Future<void> upload(String path, String name) async {
    // create StreamSubscription to handle file stream from iCloud
    StreamSubscription<double>? subscription;
    // for checking is subscription end
    Future<dynamic>? subscriptionFuture;
    bool isDone = false;

    // encrypt file before upload
    final file = File(path);

    final encryptedFile = await encryptFile(file, _credentials);

    await ICloudStorage.upload(
        containerId: _containerId,
        filePath: encryptedFile.path,
        destinationRelativePath: '/$name',
        onProgress: (stream) {
          // set subscription
          subscription = stream.listen((progress) {
            if (kDebugMode) {
              print('upload progress : $progress');
            }
            // success
          }, onDone: () {
            if (kDebugMode) {
              print('upload done!');
            }
            isDone = true;
            // on error, cancel the stream
          }, onError: (err) {
            if (kDebugMode) {
              print('upload error : $err');
            }
            throw BackupException();
          }, cancelOnError: true);
          // mark as stream started
          subscriptionFuture = subscription!.asFuture();
        }).timeout(
      const Duration(
        seconds:
            7, // check after 7 seconds, if stream is still not ended, just cancel
      ),
      onTimeout: () {
        if (!isDone) {
          // this will end stream, so subscriptionFuture also will be end
          subscription?.cancel();
          encryptedFile.delete();
          throw BackupTimeoutException();
        }
      },
    );
    // check after 7 seconds, if stream is still not ended, just cancel
    Future.delayed(const Duration(seconds: 7), () {
      if (!isDone) {
        // this will end stream, so subscriptionFuture also will be end
        subscription?.cancel();
        encryptedFile.delete();
        throw BackupTimeoutException();
      }
    });
    // wait for subscriptionFuture to end(success or error)
    await Future.wait([subscriptionFuture!]);
    if (kDebugMode) {
      print('ios cloud : upload start');
    }

    encryptedFile.delete();
    return;
  }

  @override
  Future<void> download(String name, String path) async {
    // 1. check you have instance
    // await _precheck();
    // 2. create StreamSubscription to handle file stream from iCloud
    StreamSubscription<double>? subscription;
    // 3. for checking is subscription end before accessing a downloaded file
    Future<dynamic>? subscriptionFuture;
    bool isDone = false;

    await ICloudStorage.download(
        containerId: _containerId,
        relativePath: '/$name',
        destinationFilePath: '$path.encrypted',
        // 4. set subscription
        onProgress: (stream) {
          subscription = stream.listen((progress) {
            if (kDebugMode) {
              print('download progress : $progress');
            }
            // 5. success
          }, onDone: () {
            if (kDebugMode) {
              print('download done!');
            }

            isDone = true;
            // 6. on error, cancel the stream
          }, onError: (err) {
            if (kDebugMode) {
              print('download error : $err');
            }
          }, cancelOnError: true);
          // mark as stream started
          subscriptionFuture = subscription!.asFuture();
        }).timeout(
      const Duration(
        seconds:
            7, // check after 7 seconds, if stream is still not ended, just cancel
      ),
      onTimeout: () {
        if (!isDone) {
          isDone = true;
          // this will end stream, so subscriptionFuture also will be end
          subscription?.cancel();
        }
      },
    );

    // wait for subscriptionFuture to end(success or error)
    await Future.wait([subscriptionFuture!]);
    if (kDebugMode) {
      print('ios cloud : downloaded from icloud dir');
    }

    final encryptedFile = File('$path.encrypted');

    await decryptFile(encryptedFile, _credentials);

    // delete local encrypted file
    await encryptedFile.delete();

    return;
  }

  @override
  Future<void> delete(String name) async {
    await ICloudStorage.delete(
      containerId: _containerId,
      relativePath: '/$name',
    );

    return;
  }
}
