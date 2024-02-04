import 'package:citizenwallet/services/backup/backup.dart';

class WebBackupConfig {}

class WebBackupService extends BackupServiceInterface {
  static final WebBackupService _instance = WebBackupService._internal();

  factory WebBackupService() {
    return _instance;
  }

  WebBackupService._internal();

  @override
  Future<String?> init({BackupConfigInterface? config}) async {
    return null;
  }

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
