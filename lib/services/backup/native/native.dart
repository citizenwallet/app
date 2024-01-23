import 'package:citizenwallet/services/backup/backup.dart';
import 'package:citizenwallet/services/backup/native/android.dart';
import 'package:citizenwallet/services/backup/native/icloud.dart';
import 'package:citizenwallet/utils/platform.dart';

BackupServiceInterface getBackupService() {
  return isPlatformApple() ? ICloudBackupService() : AndroidBackupService();
}
