import 'package:citizenwallet/state/share_modal/logic.dart';
import 'package:citizenwallet/state/share_modal/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class ShareModal extends StatefulWidget {
  final String title;
  final String copyLabel;
  final void Function() onCopyPrivateKey;

  const ShareModal({
    Key? key,
    this.title = 'Wallet',
    required this.copyLabel,
    required this.onCopyPrivateKey,
  }) : super(key: key);

  @override
  _ShareModalState createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> {
  late ShareModalLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = ShareModalLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //

      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _logic.setShareLink();
  }

  void onCopyShareUrl() {
    _logic.copyShareUrl();

    HapticFeedback.heavyImpact();
  }

  void handleShareWallet(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;

    _logic.shareWallet(
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

    final shareLink = context.select((ShareModalState s) => s.shareLink);

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
                        height: 400,
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
                              child: PrettyQr(
                                data: shareLink,
                                size: 200,
                                roundEdges: false,
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
                      SvgPicture.asset(
                        'assets/images/citizenwallet-qrcode.svg',
                        semanticsLabel:
                            'QR code to create a new citizen wallet',
                        height: 300,
                        width: 300,
                        colorFilter: ColorFilter.mode(
                          ThemeColors.text.resolveFrom(context),
                          BlendMode.srcIn,
                        ),
                      ),
                      const Text(
                        'Scan this QR code to create a new Citizen Wallet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      const Text(
                        'Share your own wallet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'This can be helpful to have a copy of your wallet on another device, or to give a wallet to a parent or a kid.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        '⚠️ Only share this URL with trusted parties. Anyone who has this unique URL has full access to this wallet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            Uri.base.toString(),
                            onTap: () => handleShareWallet(context),
                            fontSize: 12,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                            textColor:
                                ThemeColors.touchable.resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
                            borderRadius: 15,
                            maxWidth: 150,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      const Text(
                        'Export Private Key',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'You can export your private key to import it in the native Citizen Wallet app. Note that if you import it in metamask or in any other wallet that does not support account abstraction (ERC4337), you won\'t be able to directly see your balance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Keep this key safe, anyone with access to it has access to the account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            onTap: widget.onCopyPrivateKey,
                            widget.copyLabel,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                            textColor:
                                ThemeColors.touchable.resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
                            borderRadius: 15,
                            maxWidth: 150,
                          ),
                        ],
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
