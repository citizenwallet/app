// encryptFile takes a File and encrypts it to a new file
import 'dart:io';

import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/credentials/credentials.dart';

Future<File> encryptFile(
    File file, CredentialsServiceInterface credentials) async {
  if (!file.existsSync()) {
    throw BackupSourceMissingException();
  }

  final fileBytes = await file.readAsBytes();

  final encryptedBytes = await credentials.encrypt(fileBytes);

  final encryptedFile = File('${file.path}.encrypted');
  await encryptedFile.writeAsBytes(encryptedBytes);

  return encryptedFile;
}

Future<File> decryptFile(
    File file, CredentialsServiceInterface credentials) async {
  if (!file.existsSync()) {
    throw BackupSourceMissingException();
  }

  // decrypt the file
  final encryptedBytes = await file.readAsBytes();

  final decryptedBytes = await credentials.decrypt(encryptedBytes);

  final decryptedFile = File(file.path.replaceAll('.encrypted', ''));

  await decryptedFile.writeAsBytes(decryptedBytes);

  return decryptedFile;
}
