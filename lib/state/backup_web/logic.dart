import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/share/share.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class BackupWebLogic {
  final ConfigService _config = ConfigService();
  final SharingService _sharing = SharingService();
  final String appLinkSuffix = dotenv.get('APP_LINK_SUFFIX');
  final String deepLinkURL = dotenv.get('ORIGIN_HEADER');
  final String appUniversalURL = dotenv.get('MAIN_APP_SCHEME');

  late BackupWebState _state;

  BackupWebLogic(BuildContext context) {
    _state = context.read<BackupWebState>();
  }

  void setShareLink() async {
    try {
      final config = await _config.getWebConfig(appLinkSuffix, null);

      final link = config.community.walletUrl(deepLinkURL);
      _state.setShareLink(link);
    } catch (e) {
      //
    }
  }

  Future<void> openAppStore() async {
    try {
      launchUrl(Uri.parse(
          'https://apps.apple.com/us/app/citizen-wallet/id6460822891'));
    } catch (e) {
      //
    }
  }

  Future<void> openNativeApp() async {
    try {
      final fragment = Uri.base.fragment;

      // on the web, it will open the app or another tab no matter what
      await launchUrl(
        Uri.parse('$appUniversalURL/#$fragment'),
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      //
    }
  }

  Future<void> openPlayStore() async {
    try {
      launchUrl(Uri.parse(
          'https://play.google.com/store/apps/details?id=xyz.citizenwallet.wallet'));
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

  void composeEmail() {
    launchUrl(Uri(
      scheme: 'mailto',
      path: '',
      query:
          'subject=🔐%20Citizen%20Wallet%20Backup&body=Please%20keep%20this%20URL%20private.%20Anyone%20who%20has%20access%20to%20it%20can%20spend%20your%20funds.\n\n${Uri.base.toString()}',
    ));
  }
}
