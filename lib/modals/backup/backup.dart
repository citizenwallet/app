import 'package:citizenwallet/state/backup_web/logic.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class BackupModal extends StatefulWidget {
  final String title;

  const BackupModal({
    Key? key,
    this.title = 'Wallet',
  }) : super(key: key);

  @override
  BackupModalState createState() => BackupModalState();
}

class BackupModalState extends State<BackupModal> {
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
                            SvgPicture.asset(
                              'assets/icons/backup-file.svg',
                              semanticsLabel: 'voucher icon',
                              height: 200,
                              width: 200,
                            ),
                            const SizedBox(height: 100),
                            Text(
                              'Send yourself the backup link by email.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text(
                              "The backup link gives access to your wallet, only send it to an email address you trust.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Button(
                                  text: 'Send Link',
                                  suffix: Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.link,
                                        size: 18,
                                        color: ThemeColors.black
                                            .resolveFrom(context),
                                      ),
                                    ],
                                  ),
                                  onPressed: () => handleBackupWallet(context),
                                  minWidth: 200,
                                  maxWidth: 200,
                                ),
                              ],
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
