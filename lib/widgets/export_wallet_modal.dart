import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ExportWalletModal extends StatelessWidget {
  final String title;
  final String toCopy;
  final void Function() onCopy;

  const ExportWalletModal({
    Key? key,
    this.title = 'Wallet',
    required this.toCopy,
    required this.onCopy,
  }) : super(key: key);

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return DismissibleModalPopup(
      modaleKey: 'export-wallet-modal',
      maxHeight: height,
      paddingSides: 10,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      onDismissed: (_) => handleDismiss(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
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
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/citizenwallet-qrcode.svg',
                        semanticsLabel:
                            'QR code to create a new citizen wallet',
                        height: 300,
                        width: 300,
                        colorFilter: ColorFilter.mode(
                          ThemeColors.text.resolveFrom(context),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Private Key',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Text(
                        'Keep this key safe, anyone with access to it has access to your account.',
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
                            onTap: onCopy,
                            toCopy,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                            textColor:
                                ThemeColors.touchable.resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
