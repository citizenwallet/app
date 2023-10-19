import 'package:citizenwallet/state/backup_web/logic.dart';
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

class SaveModal extends StatefulWidget {
  const SaveModal({
    super.key,
  });

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

  void handleNativeApp() {
    _logic.openNativeApp();
  }

  void handleAppStoreLink() {
    _logic.openAppStore();
  }

  void handleGooglePlayLink() {
    _logic.openPlayStore();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    final isDesktop = !isIOS && !isAndroid;

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
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 40),
                            if (isIOS) ...[
                              Text(
                                'Get the app',
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
                              ),
                            ],
                            if (isAndroid) ...[
                              Text(
                                'Get the app',
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
                          ],
                        ),
                      ),
                      if (!isDesktop)
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Text(
                                'Open the app',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Button(
                                text: 'Open',
                                suffix: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    Icon(
                                      CupertinoIcons.arrowshape_turn_up_right,
                                      size: 18,
                                      color: ThemeColors.black
                                          .resolveFrom(context),
                                    ),
                                  ],
                                ),
                                onPressed: handleNativeApp,
                                minWidth: 200,
                                maxWidth: 200,
                              ),
                            ],
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 100),
                            Text(
                              'Or copy your wallet url and save it somewhere safe',
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
