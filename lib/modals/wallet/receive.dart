import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/strings.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/picker.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReceiveModal extends StatefulWidget {
  final WalletLogic logic;

  const ReceiveModal({super.key, required this.logic});

  @override
  ReceiveModalState createState() => ReceiveModalState();
}

class ReceiveModalState extends State<ReceiveModal> {
  final FocusNode amountFocusNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  late Debounce debouncedQRCode;

  double _opacity = 0;
  String _selectedValue = 'Citizen Wallet';
  bool _isEnteringAmount = false;
  bool _isDescribing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      _selectedValue = AppLocalizations.of(context)!.citizenWallet;

      debouncedQRCode = debounce(
        widget.logic.updateReceiveQR,
        const Duration(milliseconds: 500),
      );

      onLoad();
    });
  }

  @override
  void dispose() {
    widget.logic.stopListeningMessage();
    messageFocusNode.removeListener(handleMessageListenerUpdate);

    widget.logic.stopListeningAmount();
    amountFocusNode.removeListener(handleAmountListenerUpdate);

    widget.logic.clearInputControllers();

    super.dispose();
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    widget.logic.startListeningMessage();
    messageFocusNode.addListener(handleMessageListenerUpdate);

    widget.logic.startListeningAmount();
    amountFocusNode.addListener(handleAmountListenerUpdate);

    widget.logic.updateReceiveQR(onlyHex: true);

    handleAmount();

    setState(() {
      _opacity = 1;
    });
  }

  void handleAmountListenerUpdate() {
    if (!amountFocusNode.hasFocus) {
      handleAmountDone();
    }
  }

  void handleAmount() async {
    setState(() {
      _isEnteringAmount = true;
      _isDescribing = false;
    });

    await delay(const Duration(milliseconds: 50));

    amountFocusNode.requestFocus();
  }

  void handleAmountDone() {
    setState(() {
      _isEnteringAmount = false;
    });

    ModalScrollController.of(context)?.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void handleMessageListenerUpdate() {
    if (!messageFocusNode.hasFocus) {
      handleDescribeDone();
    }
  }

  void handleDescribe() async {
    setState(() {
      _isDescribing = true;
      _isEnteringAmount = false;
    });

    await delay(const Duration(milliseconds: 50));

    messageFocusNode.requestFocus();
  }

  void handleDescribeDone() {
    setState(() {
      _isDescribing = false;
    });

    ModalScrollController.of(context)?.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void handleCloseEditing() {
    handleDescribeDone();
    handleAmountDone();

    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleClearDescribe() {
    widget.logic.messageController.clear();

    widget.logic.updateMessage();
  }

  void handleResetQRCode() {
    widget.logic.clearInputControllers();

    widget.logic.updateReceiveQR(onlyHex: true);
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    widget.logic.clearInputControllers();

    GoRouter.of(context).pop();
  }

  void handleCopy(String qr) {
    widget.logic.copyReceiveQRToClipboard(qr);
  }

  void handleThrottledUpdateQRCode(String value) {
    debouncedQRCode();
  }

  void handleSubmit() {
    // messageFocusNode.requestFocus();
    FocusManager.instance.primaryFocus?.unfocus();
    ModalScrollController.of(context)?.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
  }

  void handleSelect(String? value) {
    setState(() {
      _selectedValue = value ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom + 100;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    const paddingSize = 40;
    final maxSize = (width < height ? width : (height - 120)) - paddingSize;
    final remainingHeight = height - keyboardHeight - paddingSize;
    final qrSize =
        remainingHeight < maxSize ? (remainingHeight - paddingSize) : maxSize;

    final qrCode = context.select((WalletState state) => state.receiveQR);

    final wallet = context.select((WalletState state) => state.wallet);

    final message = context.select(
      (WalletState state) => state.message,
    );

    final amount = context.select(
      (WalletState state) => state.amount,
    );

    final isExternalWallet =
        _selectedValue == AppLocalizations.of(context)!.externalWallet;

    final qrData = isExternalWallet ? wallet?.account ?? '' : qrCode;

    Color backgroundColor = ThemeColors.border.resolveFrom(context);

    if (amount.isNotEmpty) {
      backgroundColor = ThemeColors.success.resolveFrom(context);
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.background.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 10,
          ),
          bottom: false,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                color: ThemeColors.background,
                titleWidget: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.receive,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8F899C),
                          ),
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(5),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: ThemeColors.touchable.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10,
                    10,
                    10,
                    0,
                  ),
                  child: ListView(
                    controller: ModalScrollController.of(context),
                    physics:
                        const ScrollPhysics(parent: BouncingScrollPhysics()),
                    scrollDirection: Axis.vertical,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: _opacity,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  width: 2,
                                ),
                              ),
                              child: QR(
                                key: const Key('receive-qr-code'),
                                data: qrData,
                                size: qrSize - 80,
                                padding: const EdgeInsets.all(10),
                                logo:
                                    isExternalWallet ? null : 'assets/logo.png',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Chip(
                          isExternalWallet
                              ? formatLongText(qrData, length: 6)
                              : ellipsizeLongText(
                                  qrData.replaceFirst('https://', ''),
                                  startLength: 30,
                                  endLength: 6,
                                ),
                          onTap: () => handleCopy(qrData),
                          fontSize: 14,
                          color:
                              ThemeColors.uiBackgroundAlt.resolveFrom(context),
                          textColor: ThemeColors.touchable.resolveFrom(context),
                          suffix: Icon(
                            CupertinoIcons.square_on_square,
                            size: 14,
                            color: ThemeColors.touchable.resolveFrom(context),
                          ),
                          maxWidth: isExternalWallet ? 160 : 290,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: Picker(
                          options: [
                            AppLocalizations.of(context)!.citizenWallet,
                            AppLocalizations.of(context)!.externalWallet
                          ],
                          selected: _selectedValue,
                          handleSelect: handleSelect,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (!isExternalWallet && !_isEnteringAmount)
                        const SizedBox(
                          height: 200,
                        ),
                      if (!isExternalWallet)
                        GestureDetector(
                          onTap: handleAmount,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Row(
                              children: [
                                const Text(
                                  "Request",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                                Expanded(
                                  child: Center(
                                    child: CupertinoTextField(
                                      controller: widget.logic.amountController,
                                      placeholder: formatCurrency(0.00, ''),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: ThemeColors.success
                                            .resolveFrom(context),
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const CupertinoDynamicColor
                                            .withBrightness(
                                          color: CupertinoColors.white,
                                          darkColor: CupertinoColors.black,
                                        ),
                                        border: Border(
                                          bottom: BorderSide(
                                            color: backgroundColor,
                                          ),
                                        ),
                                      ),
                                      maxLines: 1,
                                      maxLength: 25,
                                      focusNode: amountFocusNode,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                      textInputAction: TextInputAction.done,
                                      inputFormatters: [
                                        amountFormatter,
                                      ],
                                      onChanged: handleThrottledUpdateQRCode,
                                      onSubmitted: (_) {
                                        handleSubmit();
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  wallet?.symbol ?? '',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (!isExternalWallet && _isEnteringAmount)
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Text(
                            AppLocalizations.of(context)!.description,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (!isExternalWallet && _isEnteringAmount)
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: message.isEmpty
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.spaceBetween,
                                children: [
                                  if (message.isNotEmpty)
                                    CupertinoButton(
                                      onPressed: handleClearDescribe,
                                      child: Text(
                                        AppLocalizations.of(context)!.clear,
                                        style: TextStyle(
                                          color: ThemeColors.danger
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              CupertinoTextField(
                                controller: widget.logic.messageController,
                                placeholder:
                                    '${AppLocalizations.of(context)!.descriptionMsg}\n\n\n',
                                minLines: 4,
                                maxLines: 10,
                                maxLength: 200,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.newline,
                                textAlignVertical: TextAlignVertical.top,
                                focusNode: messageFocusNode,
                                autocorrect: true,
                                enableSuggestions: true,
                                onChanged: handleThrottledUpdateQRCode,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if ((_isEnteringAmount || _isDescribing) && !isExternalWallet)
                const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
