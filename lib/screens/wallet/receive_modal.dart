import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:rate_limiter/rate_limiter.dart';

class ReceiveModal extends StatefulWidget {
  final WalletLogic logic;

  const ReceiveModal({Key? key, required this.logic}) : super(key: key);

  @override
  ReceiveModalState createState() => ReceiveModalState();
}

class ReceiveModalState extends State<ReceiveModal> {
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  late void Function() debouncedQRCode;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      widget.logic.updateReceiveQR(onlyHex: true);

      debouncedQRCode = debounce(
        widget.logic.updateReceiveQR,
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    widget.logic.clearInputControllers();

    GoRouter.of(context).pop();
  }

  void handleCopy() {
    widget.logic.copyReceiveQRToClipboard();
  }

  void handleThrottledUpdateQRCode() {
    debouncedQRCode();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final qrSize = width - 40;

    final qrCode = context.select((WalletState state) => state.receiveQR);

    final wallet = context.select((WalletState state) => state.wallet);

    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

    return DismissibleModalPopup(
      modaleKey: 'receive-modal',
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
                            onPressed: handleCopy,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      const Text(
                        'Amount',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: widget.logic.amountController,
                        placeholder: formatCurrency(1050.00, ''),
                        prefix: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: Text(
                              wallet?.symbol ?? '',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        decoration: invalidAmount
                            ? BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color: ThemeColors.danger,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              )
                            : BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color:
                                      ThemeColors.border.resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                        maxLines: 1,
                        maxLength: 25,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          amountFormatter,
                        ],
                        onChanged: (_) {
                          handleThrottledUpdateQRCode();
                        },
                        onSubmitted: (_) {
                          messageFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Message',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: widget.logic.messageController,
                        placeholder: 'Enter a message',
                        maxLines: 4,
                        maxLength: 256,
                        focusNode: messageFocusNode,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) {
                          handleThrottledUpdateQRCode();
                        },
                        onSubmitted: (_) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
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
