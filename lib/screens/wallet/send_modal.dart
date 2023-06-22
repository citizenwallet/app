import 'dart:async';

import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class SendModal extends StatefulWidget {
  final WalletLogic logic;

  final String? to;

  const SendModal({
    Key? key,
    required this.logic,
    this.to,
  }) : super(key: key);

  @override
  SendModalState createState() => SendModalState();
}

class SendModalState extends State<SendModal> with TickerProviderStateMixin {
  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;

  final FocusNode amountFocuseNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final double animationSize = 200;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();

      debouncedAddressUpdate = debounce(
        widget.logic.updateAddress,
        const Duration(milliseconds: 500),
      );

      debouncedAmountUpdate = debounce(
        widget.logic.updateAmount,
        const Duration(milliseconds: 500),
      );
    });
  }

  void onLoad() {
    if (widget.to != null) {
      return;
    }
    handleQRScan();
  }

  void handleDismiss(BuildContext context) {
    widget.logic.clearInputControllers();
    widget.logic.resetInputErrorState();

    GoRouter.of(context).pop();
  }

  void handleThrottledUpdateAddress() {
    debouncedAddressUpdate();
  }

  void handleThrottledUpdateAmount() {
    debouncedAmountUpdate();
  }

  void handleQRScan() async {
    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Scanner(
        modalKey: 'send-form-anything-scanner',
      ),
    );

    if (result != null) {
      widget.logic.updateFromCapture(result);
    }
  }

  void handleSend(BuildContext context) async {
    if (_isSending) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final isValid = widget.logic.validateSendFields(
      widget.logic.amountController.value.text,
      widget.logic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    widget.logic.sendTransaction(
      widget.logic.amountController.value.text,
      widget.logic.addressController.value.text,
      message: widget.logic.messageController.value.text,
    );

    widget.logic.clearInputControllers();
    widget.logic.resetInputErrorState();

    await Future.delayed(const Duration(milliseconds: 250));

    HapticFeedback.heavyImpact();

    navigator.pop();
    return;
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final invalidAddress = context.select(
      (WalletState state) => state.invalidAddress,
    );
    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

    final hasAddress = context.select(
      (WalletState state) => state.hasAddress,
    );

    final hasAmount = context.select(
      (WalletState state) => state.hasAmount,
    );

    final parsingQRAddressError = context.select(
      (WalletState state) => state.parsingQRAddressError,
    );

    final transactionSendError = context.select(
      (WalletState state) => state.transactionSendError,
    );

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return DismissibleModalPopup(
      modaleKey: 'send-form',
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
                  title: 'Send',
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ListView(
                        scrollDirection: Axis.vertical,
                        children: [
                          const SizedBox(height: 20),
                          if (widget.to == null)
                            const Text(
                              'To',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          if (widget.to == null) const SizedBox(height: 10),
                          if (widget.to != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                Chip(
                                  formatHexAddress(widget.to!),
                                  color: ThemeColors.subtleEmphasis
                                      .resolveFrom(context),
                                  textColor: ThemeColors.touchable
                                      .resolveFrom(context),
                                  maxWidth: 160,
                                ),
                              ],
                            ),
                          if (widget.to == null)
                            CupertinoTextField(
                              controller: widget.logic.addressController,
                              placeholder: 'Enter an address',
                              maxLines: 1,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => handleThrottledUpdateAddress(),
                              decoration: invalidAddress ||
                                      parsingQRAddressError ||
                                      transactionSendError
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
                              prefix: Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: Icon(
                                    CupertinoIcons.creditcard,
                                    color: hasAddress
                                        ? ThemeColors.text.resolveFrom(context)
                                        : ThemeColors.subtleEmphasis
                                            .resolveFrom(context),
                                  ),
                                ),
                              ),

                              /// TODO: selection from contacts
                              // suffix: GestureDetector(
                              //   onTap:
                              //       parsingQRAddress ? null : handleQRAddressScan,
                              //   child: Center(
                              //     child: Padding(
                              //       padding:
                              //           const EdgeInsets.fromLTRB(10, 0, 10, 0),
                              //       child: parsingQRAddress
                              //           ? CupertinoActivityIndicator(
                              //               color: ThemeColors.background
                              //                   .resolveFrom(context),
                              //             )
                              //           : Icon(
                              //               CupertinoIcons.person_alt,
                              //               color: ThemeColors.primary
                              //                   .resolveFrom(context),
                              //             ),
                              //     ),
                              //   ),
                              // ),
                              onSubmitted: (_) {
                                amountFocuseNode.requestFocus();
                              },
                            ),
                          const SizedBox(height: 20),
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
                            decoration: invalidAmount || transactionSendError
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
                            focusNode: amountFocuseNode,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: false,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              amountFormatter,
                            ],
                            onChanged: (_) => handleThrottledUpdateAmount(),
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
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Button(
                                text: 'Scan',
                                color: ThemeColors.surfaceSubtle
                                    .resolveFrom(context),
                                labelColor:
                                    ThemeColors.text.resolveFrom(context),
                                suffix: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                  child: Icon(
                                    CupertinoIcons.qrcode_viewfinder,
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                                onPressed: handleQRScan,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 90,
                          ),
                        ],
                      ),
                      if (_isSending)
                        Positioned(
                          bottom: 90,
                          child: CupertinoActivityIndicator(
                            color: ThemeColors.subtle.resolveFrom(context),
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        child: SizedBox(
                          height: 90,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                            child: SlideToComplete(
                              onCompleted: !_isSending
                                  ? () => handleSend(context)
                                  : null,
                              enabled: hasAddress &&
                                  hasAmount &&
                                  !invalidAmount &&
                                  !invalidAddress,
                              isComplete: _isSending,
                              completionLabel:
                                  _isSending ? 'Sending...' : 'Send',
                              thumbColor: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              width: width * 0.5,
                              child: const SizedBox(
                                height: 50,
                                width: 50,
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_right,
                                    color: ThemeColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
