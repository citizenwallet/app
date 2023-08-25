import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/share/share.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class BackupWebLogic {
  final ConfigService _config = ConfigService();
  final SharingService _sharing = SharingService();
  final String appLinkSuffix = dotenv.get('APP_LINK_SUFFIX');

  late BackupWebState _state;

  BackupWebLogic(BuildContext context) {
    _state = context.read<BackupWebState>();
  }

  void setShareLink() async {
    try {
      final config = await _config.config;

      final link = 'https://${config.community.alias}$appLinkSuffix';
      _state.setShareLink(link);
    } catch (e) {
      //
    }
  }

  Future<void> backupWallet(Rect sharePositionOrigin) async {
    try {
      await _sharing.shareWallet(
        Uri.base.toString(),
        sharePositionOrigin,
      );
    } catch (e) {
      //
    }
  }

  void copyShareUrl() {
    Clipboard.setData(ClipboardData(text: _state.shareLink));
  }

  void copyUrl() {
    Clipboard.setData(ClipboardData(text: Uri.base.toString()));
  }
}
