import 'package:citizenwallet/services/backup/backup.dart';

class WebBackupConfig {}

class WebBackupService extends BackupServiceInterface {
  WebBackupService();

  @override
  Future<void> init(BackupConfigInterface config) async {}

  @override
  Future<(String?, DateTime?)> backupExists(String name) {
    return Future.value((null, null));
  }

  @override
  upload(String path, String name) {}

  @override
  download(String name, String path) {}

  @override
  delete(String name) {}
}

BackupServiceInterface getBackupService() {
  return WebBackupService();
}
