import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';

enum BackupStatus {
  account("Setting up account."),
  e2e("Setting up end-to-end encryption."),
  restore("Restoring from backup."),
  nobackup("No backup found."),
  success("Restore successful."),
  error("Restore failed."),
  ;

  const BackupStatus(this.message);

  final String message;
}

class BackupState with ChangeNotifier {
  bool loading = false;
  bool error = false;

  DateTime? lastBackup;

  BackupStatus? status;

  bool e2eEnabled = false;

  BackupState() {
    final lastTime = PreferencesService().getLastBackupTime();
    if (lastTime != null) {
      lastBackup = DateTime.tryParse(lastTime);
    }
  }

  void checkRecoverRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void checkRecoverSuccess() {
    loading = false;
    error = false;
    notifyListeners();
  }

  void checkRecoverError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void backupRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void backupSuccess(DateTime? lastBackup) {
    this.lastBackup = lastBackup;
    loading = false;
    error = false;
    e2eEnabled = true;
    notifyListeners();
  }

  void backupError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void setStatus(BackupStatus? status) {
    this.status = status;
    notifyListeners();
  }

  void setE2E(bool enabled) {
    e2eEnabled = enabled;
    notifyListeners();
  }
}
