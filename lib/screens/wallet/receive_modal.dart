import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
  final FocusNode amountFocusNode = FocusNode();
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

      amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    widget.logic.clearInputControllers();

    GoRouter.of(context).pop();
  }

  void handleCopy(String qr) {
    widget.logic.copyReceiveQRToClipboard(qr);
  }

  void handleThrottledUpdateQRCode() {
    debouncedQRCode();
  }

  void handleReset() {
    widget.logic.clearInputControllers();

    widget.logic.updateReceiveQR(onlyHex: true);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final qrSize = (width < height ? width : (height - 100)) - 40;
    final minQRSize = qrSize * 0.05;

    final qrCode = context.select((WalletState state) => state.receiveQR);

    final wallet = context.select((WalletState state) => state.wallet);

    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

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
                  controller: ModalScrollController.of(context),
                  scrollBehavior: const CupertinoScrollBehavior(),
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
                            Chip(
                              formatHexAddress(wallet?.account ?? ''),
                              onTap: wallet?.account == null
                                  ? null
                                  : () => handleCopy(wallet?.account ?? ''),
                              fontSize: 14,
                              color: ThemeColors.subtleEmphasis
                                  .resolveFrom(context),
                              textColor:
                                  ThemeColors.touchable.resolveFrom(context),
                              suffix: Icon(
                                CupertinoIcons.square_on_square,
                                size: 14,
                                color:
                                    ThemeColors.touchable.resolveFrom(context),
                              ),
                              borderRadius: 15,
                              maxWidth: 150,
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
                                    color:
                                        ThemeColors.border.resolveFrom(context),
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5.0)),
                                ),
                          maxLines: 1,
                          maxLength: 25,
                          focusNode: amountFocusNode,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            amountFormatter,
                          ],
                          onChanged: (_) {
                            handleThrottledUpdateQRCode();
                          },
                          onSubmitted: (_) {
                            // messageFocusNode.requestFocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 20,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Reset QR Code',
                            onPressed: handleReset,
                            minWidth: 200,
                            maxWidth: 200,
                          ),
                        ],
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 20,
                      ),
                    ),
                    // const SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    //     child: Text(
                    //       'Description',
                    //       style: TextStyle(
                    //           fontSize: 24, fontWeight: FontWeight.bold),
                    //     ),
                    //   ),
                    // ),
                    // const SliverToBoxAdapter(
                    //   child: SizedBox(
                    //     height: 10,
                    //   ),
                    // ),
                    // SliverToBoxAdapter(
                    //   child: Padding(
                    //     padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    //     child: CupertinoTextField(
                    //       controller: widget.logic.messageController,
                    //       placeholder: 'Enter a description',
                    //       maxLines: 4,
                    //       maxLength: 256,
                    //       focusNode: messageFocusNode,
                    //       textInputAction: TextInputAction.done,
                    //       onChanged: (_) {
                    //         handleThrottledUpdateQRCode();
                    //       },
                    //       onSubmitted: (_) {
                    //         FocusManager.instance.primaryFocus?.unfocus();
                    //       },
                    //     ),
                    //   ),
                    // ),
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
    );
  }
}
