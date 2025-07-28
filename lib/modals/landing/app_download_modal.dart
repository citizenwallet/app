import 'package:citizenwallet/state/backup_web/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class AppDownloadModal extends StatefulWidget {
  final String? title;
  final String? message;

  const AppDownloadModal({
    super.key,
    this.title,
    this.message,
  });

  @override
  AppDownloadModalState createState() => AppDownloadModalState();
}

class AppDownloadModalState extends State<AppDownloadModal> {
  late BackupWebLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = BackupWebLogic(context);
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  void handleAppStoreLink() {
    _logic.openAppStore();
  }

  void handleGooglePlayLink() {
    _logic.openPlayStore();
  }

  void handleNativeApp() {
    _logic.openNativeApp();
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final isDesktop = !isIOS && !isAndroid;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: widget.title ?? AppLocalizations.of(context)!.gettheapp,
                showBackButton: true,
              ),
              Expanded(
                child: CustomScrollView(
                  scrollBehavior: const CupertinoScrollBehavior(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          SvgPicture.asset(
                            'assets/citizenwallet-only-logo.svg',
                            semanticsLabel: 'Citizen Wallet Icon',
                            height: 120,
                          ),
                          const SizedBox(height: 30),
                          if (widget.message != null) ...[
                            Text(
                              widget.message!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                          if (isIOS) ...[
                            Text(
                              AppLocalizations.of(context)!.gettheapp,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CupertinoButton(
                              onPressed: handleAppStoreLink,
                              child: SvgPicture.asset(
                                'assets/images/app-store-badge.svg',
                                semanticsLabel:
                                    AppLocalizations.of(context)!.appstorebadge,
                                height: 70,
                              ),
                            ),
                          ],
                          if (isAndroid) ...[
                            Text(
                              AppLocalizations.of(context)!.gettheapp,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            CupertinoButton(
                              onPressed: handleGooglePlayLink,
                              child: Image.asset(
                                'assets/images/google-play-badge.png',
                                semanticLabel: AppLocalizations.of(context)!
                                    .googleplaybadge,
                                height: 100,
                              ),
                            ),
                          ],
                          if (isDesktop) ...[
                            Text(
                              AppLocalizations.of(context)!.gettheapp,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  onPressed: handleAppStoreLink,
                                  child: SvgPicture.asset(
                                    'assets/images/app-store-badge.svg',
                                    semanticsLabel:
                                        AppLocalizations.of(context)!
                                            .appstorebadge,
                                    height: 60,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                CupertinoButton(
                                  onPressed: handleGooglePlayLink,
                                  child: Image.asset(
                                    'assets/images/google-play-badge.png',
                                    semanticLabel: AppLocalizations.of(context)!
                                        .googleplaybadge,
                                    height: 80,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!isDesktop) ...[
                            const SizedBox(height: 40),
                            Text(
                              AppLocalizations.of(context)!.opentheapp,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Button(
                              text: AppLocalizations.of(context)!.open,
                              suffix: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Icon(
                                    CupertinoIcons.arrowshape_turn_up_right,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colors
                                        .black
                                        .resolveFrom(context),
                                  ),
                                ],
                              ),
                              onPressed: handleNativeApp,
                              minWidth: 200,
                              maxWidth: 200,
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
