import 'package:citizenwallet/state/backup_web/logic.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SaveModal extends StatefulWidget {
  const SaveModal({
    Key? key,
  }) : super(key: key);

  @override
  SaveModalState createState() => SaveModalState();
}

class SaveModalState extends State<SaveModal> {
  double _opacity = 0;

  late BackupWebLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = BackupWebLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //

      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _logic.setShareLink();

    setState(() {
      _opacity = 1;
    });
  }

  void onCopyShareUrl() {
    _logic.copyShareUrl();

    HapticFeedback.heavyImpact();
  }

  void handleBackupWallet(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;

    _logic.backupWallet(
      box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void onCopyUrl() {
    _logic.copyUrl();

    HapticFeedback.heavyImpact();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  void handleAppStoreLink() {
    launchUrl(
        Uri.parse('https://apps.apple.com/us/app/citizen-wallet/id6460822891'));
  }

  void handleGooglePlayLink() {
    launchUrl(Uri.parse(
        'https://play.google.com/store/apps/details?id=xyz.citizenwallet.wallet'));
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    final isDesktop = !isIOS && !isAndroid;

    final width = MediaQuery.of(context).size.width;

    final shareLink = context.select((BackupWebState s) => s.shareLink);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: 'Save Wallet',
                actionButton: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color: ThemeColors.touchable.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: CustomScrollView(
                    controller: ModalScrollController.of(context),
                    scrollBehavior: const CupertinoScrollBehavior(),
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (isIOS) ...[
                              Text(
                                'Backup to iCloud Keychain by using our iOS app',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              CupertinoButton(
                                onPressed: handleAppStoreLink,
                                child: SvgPicture.asset(
                                  'assets/images/app-store-badge.svg',
                                  semanticsLabel: 'app store badge',
                                  height: 70,
                                ),
                              )
                            ],
                            if (isAndroid) ...[
                              Text(
                                'Backup to Google Drive by using our Android app',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              CupertinoButton(
                                onPressed: handleGooglePlayLink,
                                child: Image.asset(
                                  'assets/images/google-play-badge.png',
                                  semanticLabel: 'google play badge',
                                  height: 100,
                                ),
                              )
                            ],
                            if (isDesktop) ...[
                              Text(
                                'Bookmark this page to backup your wallet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SvgPicture.asset(
                                'assets/icons/bookmark_color.svg',
                                semanticsLabel: 'bookmark icon',
                                height: 100,
                              ),
                            ],
                            const SizedBox(height: 100),
                            Text(
                              'Copy your wallet url and save it somewhere safe',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Button(
                              text: 'Copy URL',
                              suffix: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Icon(
                                    CupertinoIcons.link,
                                    size: 18,
                                    color:
                                        ThemeColors.black.resolveFrom(context),
                                  ),
                                ],
                              ),
                              onPressed: () => handleBackupWallet(context),
                              minWidth: 200,
                              maxWidth: 200,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
