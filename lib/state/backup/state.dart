import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';

enum BackupStatus {
  account("Setting up account."),
  e2e("Setting up end-to-end encryption."),
  restore("Restoring from backup."),
  nobackup("No backup found."),
  nokey("No encryption key found."),
  wrongkey("Wrong encryption key."),
  success("Restore successful."),
  error("Restore failed."),
  ;

  const BackupStatus(this.message);

  final String message;
}

class BackupState with ChangeNotifier {
  bool loading = false;
  bool error = false;

  String? accountName;
  DateTime? lastBackup;

  BackupStatus? status;

  bool e2eEnabled = false;

  BackupState() {
    final lastTime = PreferencesService().getLastBackupTime();
    if (lastTime != null) {
      lastBackup = DateTime.tryParse(lastTime);
    }
    final accountName = PreferencesService().getLastBackupName();
    if (accountName != null) {
      this.accountName = accountName;
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

  void backupSuccess(DateTime? lastBackup, String? accountName) {
    this.lastBackup = lastBackup;
    this.accountName = accountName;
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

  void decryptRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void decryptSuccess(DateTime? lastBackup, String? accountName) {
    this.lastBackup = lastBackup;
    this.accountName = accountName;
    loading = false;
    error = false;
    e2eEnabled = true;
    notifyListeners();
  }

  void decryptError({BackupStatus? status = BackupStatus.error}) {
    loading = false;
    error = true;
    this.status = status;
    notifyListeners();
  }

  void resetState() {
    loading = false;
    error = false;
    status = null;
    e2eEnabled = false;
  }
}
