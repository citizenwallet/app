import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QRModal extends StatelessWidget {
  final String title;
  final String qrCode;
  final void Function()? onCopy;
  final void Function({bool? onlyHex})? onUpdate;

  const QRModal({
    Key? key,
    this.title = 'Wallet',
    required this.qrCode,
    this.onCopy,
    this.onUpdate,
  }) : super(key: key);

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final qrSize = width - 40;

    return DismissibleModalPopup(
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
                  actionButton: GestureDetector(
                    onTap: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: ThemeColors.white.resolveFrom(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: PrettyQr(
                          data: qrCode,
                          size: qrSize,
                          roundEdges: false,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (onCopy != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Button(
                              text: 'Copy',
                              color: ThemeColors.primary.resolveFrom(context),
                              suffix: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Icon(
                                  CupertinoIcons.square_on_square,
                                  color: ThemeColors.white.resolveFrom(context),
                                ),
                              ),
                              onPressed: onCopy,
                            )
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
