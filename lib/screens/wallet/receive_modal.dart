import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
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

    final qrSize = (width < height ? width : (height - 100)) - 40;
    final minQRSize = qrSize / 2;

    final qrCode = context.select((WalletState state) => state.receiveQR);

    final wallet = context.select((WalletState state) => state.wallet);

    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

    return DismissibleModalPopup(
      modaleKey: 'receive-modal',
      maxHeight: height,
      paddingSides: 0,
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
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        floating: false,
                        delegate: PersistentHeaderDelegate(
                          expandedHeight: qrSize + 110,
                          minHeight: minQRSize + 80,
                          blur: true,
                          builder: (context, shrink) => Flex(
                            direction: Axis.vertical,
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: progressiveClamp(
                                    minQRSize + 20,
                                    qrSize + 20,
                                    shrink,
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: progressiveClamp(
                                        minQRSize + 20,
                                        qrSize + 20,
                                        shrink,
                                      ),
                                      width: progressiveClamp(
                                        minQRSize + 20,
                                        qrSize + 20,
                                        shrink,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ThemeColors.white
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: PrettyQr(
                                        key: const Key('receive-qr-code'),
                                        data: qrCode,
                                        size: progressiveClamp(
                                          minQRSize,
                                          qrSize,
                                          shrink,
                                        ),
                                        roundEdges: false,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Button(
                                text: 'Copy',
                                color: ThemeColors.surfacePrimary
                                    .resolveFrom(context),
                                labelColor: ThemeColors.black,
                                suffix: const Padding(
                                  padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Icon(
                                    CupertinoIcons.square_on_square,
                                    size: 14,
                                    color: ThemeColors.black,
                                  ),
                                ),
                                onPressed: handleCopy,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 10,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Text(
                            'Amount',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 10,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: CupertinoTextField(
                            controller: widget.logic.amountController,
                            placeholder: formatCurrency(1050.00, ''),
                            prefix: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: Text(
                                  wallet?.symbol ?? '',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            decoration: invalidAmount
                                ? BoxDecoration(
                                    color: const CupertinoDynamicColor
                                        .withBrightness(
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
                                    color: const CupertinoDynamicColor
                                        .withBrightness(
                                      color: CupertinoColors.white,
                                      darkColor: CupertinoColors.black,
                                    ),
                                    border: Border.all(
                                      color: ThemeColors.border
                                          .resolveFrom(context),
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
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 20,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Text(
                            'Message',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 10,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: CupertinoTextField(
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
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(
                          height: 160,
                        ),
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
