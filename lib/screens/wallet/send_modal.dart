import 'dart:async';

import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SendModal extends StatefulWidget {
  final WalletLogic logic;

  const SendModal({Key? key, required this.logic}) : super(key: key);

  @override
  SendModalState createState() => SendModalState();
}

class SendModalState extends State<SendModal> with TickerProviderStateMixin {
  late final AnimationController _controller;

  final FocusNode amountFocuseNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final double animationSize = 200;

  bool _hasAddress = false;
  bool _isSending = false;
  double _percentage = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    widget.logic.clearInputControllers();

    Navigator.of(context).pop();
  }

  void handleAddressUpdate(String s) {
    if (s.isNotEmpty) {
      setState(() {
        _hasAddress = true;
      });
    } else {
      setState(() {
        _hasAddress = false;
      });
    }
  }

  void handleQRScan() async {
    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Scanner(
        modalKey: 'send-form-scanner',
      ),
    );

    if (result != null) {
      widget.logic.updateAddressFromCapture(result);
    }
  }

  void handleSend(BuildContext context) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    _controller.repeat();

    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(milliseconds: 1000));

    final confirm = await widget.logic.sendTransaction(
      widget.logic.amountController.value.text,
      widget.logic.addressController.value.text,
      message: widget.logic.messageController.value.text,
    );

    _controller.stop();

    if (confirm) {
      HapticFeedback.heavyImpact();

      navigator.pop();
      return;
    }

    setState(() {
      _isSending = false;
      _percentage = 0;
    });
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

    final parsingQRAddress = context.select(
      (WalletState state) => state.parsingQRAddress,
    );

    final parsingQRAddressError = context.select(
      (WalletState state) => state.parsingQRAddressError,
    );

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return DismissibleModalPopup(
      modalKey: 'send-form',
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
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ListView(
                        scrollDirection: Axis.vertical,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            'To',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          CupertinoTextField(
                            controller: widget.logic.addressController,
                            placeholder: 'Enter an address',
                            maxLines: 1,
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.next,
                            onChanged:
                                parsingQRAddress ? null : handleAddressUpdate,
                            decoration: invalidAddress || parsingQRAddressError
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
                                  color: _hasAddress
                                      ? ThemeColors.text.resolveFrom(context)
                                      : ThemeColors.subtleEmphasis
                                          .resolveFrom(context),
                                ),
                              ),
                            ),
                            suffix: GestureDetector(
                              onTap: parsingQRAddress ? null : handleQRScan,
                              child: Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                  child: parsingQRAddress
                                      ? CupertinoActivityIndicator(
                                          color: ThemeColors.background
                                              .resolveFrom(context),
                                        )
                                      : Icon(
                                          CupertinoIcons.qrcode_viewfinder,
                                          color: ThemeColors.primary
                                              .resolveFrom(context),
                                        ),
                                ),
                              ),
                            ),
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
                          const SizedBox(height: 5),
                        ],
                      ),
                      Positioned(
                        bottom: 90,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: animationSize,
                              width: animationSize,
                              child: Center(
                                child: Lottie.asset(
                                  'assets/lottie/wallet_loader.json',
                                  height: (_percentage * animationSize),
                                  width: (_percentage * animationSize),
                                  controller: _controller,
                                ),
                              ),
                            ),
                          ],
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
                              isComplete: _isSending,
                              onSlide: (percentage) {
                                if (percentage == 1) {
                                  setState(() {
                                    _percentage = 1;
                                  });
                                } else {
                                  setState(() {
                                    _percentage = percentage;
                                  });
                                }
                              },
                              completionLabel:
                                  _isSending ? 'Sending...' : 'Slide to send',
                              thumbColor:
                                  ThemeColors.primary.resolveFrom(context),
                              width: width * 0.8,
                              child: SizedBox(
                                height: 50,
                                width: 50,
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.arrow_right,
                                    color:
                                        ThemeColors.white.resolveFrom(context),
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
