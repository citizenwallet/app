import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';

class BackupState with ChangeNotifier {
  bool loading = false;
  bool error = false;

  DateTime? lastBackup;

  BackupState() {
    final lastTime = PreferencesService().getLastBackupTime();
    if (lastTime != null) {
      lastBackup = DateTime.tryParse(lastTime);
    }
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
    notifyListeners();
  }

  void backupError() {
    loading = false;
    error = true;
    notifyListeners();
  }
}
