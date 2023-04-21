import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QRModal extends StatelessWidget {
  final WalletLogic logic;

  const QRModal({Key? key, required this.logic}) : super(key: key);

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCopy() {
    logic.copyWalletQRToClipboard();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final qrSize = width - 40;

    final qrCode = context.select((WalletState state) => state.walletQR);

    return DismissibleModalPopup(
      modalKey: 'wallet-qr-modal',
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
                  title: 'Receive',
                  manualBack: true,
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
                          roundEdges: true,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Copy',
                            color: ThemeColors.primary.resolveFrom(context),
                            suffix: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.doc_on_clipboard,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                            onPressed: handleCopy,
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
