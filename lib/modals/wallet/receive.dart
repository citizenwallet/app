import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/strings.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/picker.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
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

  late Debounce debouncedQRCode;

  double _opacity = 0;
  String _selectedValue = 'Citizen Wallet';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      debouncedQRCode = debounce(
        (String value) => widget.logic.updateReceiveQR(
            onlyHex: value == '' || (double.tryParse(value) ?? 0.0) == 0.0),
        const Duration(milliseconds: 500),
      );

      amountFocusNode.requestFocus();

      onLoad();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    widget.logic.updateReceiveQR(onlyHex: true);

    setState(() {
      _opacity = 1;
    });
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
    debouncedQRCode([value]);
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

    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

    final isExternalWallet = _selectedValue == 'External Wallet';

    final qrData = isExternalWallet ? wallet?.account ?? '' : qrCode;

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
                    SliverToBoxAdapter(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedOpacity(
                            opacity: _opacity,
                            duration: const Duration(milliseconds: 250),
                            child: QR(
                              key: const Key('receive-qr-code'),
                              data: qrData,
                              size: qrSize - 20,
                              padding: const EdgeInsets.all(20),
                              logo: isExternalWallet ? null : 'assets/logo.png',
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Chip(
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
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                            textColor:
                                ThemeColors.touchable.resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
                            maxWidth: isExternalWallet ? 160 : 290,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Picker(
                            options: const [
                              'Citizen Wallet',
                              'External Wallet'
                            ],
                            selected: _selectedValue,
                            handleSelect: handleSelect,
                          ),
                        ],
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
              if (!isExternalWallet)
                const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Text(
                        'Amount',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              if (!isExternalWallet)
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Center(
                    child: CupertinoTextField(
                      controller: widget.logic.amountController,
                      placeholder: formatCurrency(1500.00, ''),
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
                              color: const CupertinoDynamicColor.withBrightness(
                                color: CupertinoColors.white,
                                darkColor: CupertinoColors.black,
                              ),
                              border: Border.all(
                                color: ThemeColors.danger,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
                            )
                          : BoxDecoration(
                              color: const CupertinoDynamicColor.withBrightness(
                                color: CupertinoColors.white,
                                darkColor: CupertinoColors.black,
                              ),
                              border: Border.all(
                                color: ThemeColors.border.resolveFrom(context),
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(5.0)),
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
                      onChanged: handleThrottledUpdateQRCode,
                      onSubmitted: (_) {
                        handleSubmit();
                      },
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
