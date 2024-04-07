import 'package:citizenwallet/state/backup_web/logic.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShareModal extends StatefulWidget {
  final String title;

  const ShareModal({
    super.key,
    this.title = 'Wallet',
  });

  @override
  ShareModalState createState() => ShareModalState();
}

class ShareModalState extends State<ShareModal> {
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

  bool _tapped = false;

  Timer? _timer;

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

    setState(() {
      _tapped = true;
    });

    _timer = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _tapped = false;
      });
    });
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final shareLink = context.select((BackupWebState s) => s.shareLink);

    final config = context.select((WalletState s) => s.config);

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
                title: widget.title,
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
                  child: ListView(
                    controller: ModalScrollController.of(context),
                    physics:
                        const ScrollPhysics(parent: BouncingScrollPhysics()),
                    scrollDirection: Axis.vertical,
                    children: [
                      const SizedBox(
                        height: 30,
                      ),
                      SizedBox(
                        height: 500,
                        width: width,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: ThemeColors.white.resolveFrom(context),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.fromLTRB(
                                40,
                                60,
                                40,
                                60,
                              ),
                              margin: const EdgeInsets.only(top: 80),
                              child: AnimatedOpacity(
                                opacity: _opacity,
                                duration: const Duration(milliseconds: 250),
                                child: QR(
                                  data: shareLink,
                                  size: 300,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              child: ProfileCircle(
                                size: 100,
                                imageUrl: config?.community.logo ??
                                    'assets/logo_small.png',
                                borderColor: ThemeColors.subtle,
                                backgroundColor: ThemeColors.white,
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 44,
                                  ),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 200,
                                    ),
                                    child: Text(
                                      _tapped
                                          ? '${AppLocalizations.of(context)!.copied} !'
                                          : shareLink.replaceFirst(
                                              'https://', ''),
                                      style: TextStyle(
                                        color: ThemeColors.black
                                            .resolveFrom(context),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    onPressed: onCopyShareUrl,
                                    child: Icon(
                                      CupertinoIcons.square_on_square,
                                      size: 14,
                                      color: ThemeColors.black
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                       Text(
                        AppLocalizations.of(context)!.shareText1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                       Text(
                        AppLocalizations.of(context)!.shareText2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
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
