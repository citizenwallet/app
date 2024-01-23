export 'native/native.dart' if (dart.library.html) 'web.dart';

class BackupTimeoutException implements Exception {
  final String message = 'backup timeout';

  BackupTimeoutException();
}

class BackupNotFoundException implements Exception {
  final String message = 'backup not found';

  BackupNotFoundException();
}

class BackupSourceMissingException implements Exception {
  final String message = 'backup source missing';

  BackupSourceMissingException();
}

class BackupException implements Exception {
  final String message = 'backup error';

  BackupException();
}

abstract class BackupConfigInterface {}

abstract class BackupServiceInterface {
  BackupServiceInterface();

  Future<void> init(BackupConfigInterface config) async {}

  Future<String?> backupExists(String name) {
    return Future.value(null);
  }

  upload(String path, String name) {}

  download(String name, String path) {}

  delete(String name) {}
}
