import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ShareModal extends StatelessWidget {
  final String title;
  final String copyLabel;
  final void Function() onCopyPrivateKey;

  const ShareModal({
    Key? key,
    this.title = 'Wallet',
    required this.copyLabel,
    required this.onCopyPrivateKey,
  }) : super(key: key);

  void onCopyUrl() {
    Clipboard.setData(ClipboardData(text: Uri.base.toString()));

    HapticFeedback.heavyImpact();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: title,
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    children: [
                      const SizedBox(
                        height: 40,
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
                            onTap: onCopyUrl,
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
                            onTap: onCopyPrivateKey,
                            copyLabel,
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
