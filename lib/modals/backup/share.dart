import 'package:citizenwallet/state/backup_web/logic.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class ShareModal extends StatefulWidget {
  final String title;

  const ShareModal({
    Key? key,
    this.title = 'Wallet',
  }) : super(key: key);

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

  void onCopyUrl() {
    _logic.copyUrl();

    HapticFeedback.heavyImpact();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                        height: 40,
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
                                40,
                                40,
                                60,
                              ),
                              margin: const EdgeInsets.only(top: 80),
                              child: AnimatedOpacity(
                                opacity: _opacity,
                                duration: const Duration(milliseconds: 250),
                                child: PrettyQr(
                                  data: shareLink,
                                  size: 300,
                                  roundEdges: false,
                                ),
                              ),
                            ),
                            const Positioned(
                              top: 10,
                              child: ProfileCircle(
                                size: 100,
                                imageUrl: 'assets/logo_small.png',
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
                                      shareLink,
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
                      const Text(
                        'Get someone else to scan this QR code.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        "If they don't already have one, it will create a new Citizen Wallet on their device",
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
