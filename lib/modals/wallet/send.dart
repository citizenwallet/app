import 'dart:async';

import 'package:citizenwallet/modals/wallet/pick_sender.dart';
import 'package:citizenwallet/modals/wallet/voucher.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/scanner/scanner.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class SendModal extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;

  final String? id;
  final String? to;
  final String? amount;

  final String? receiveParams;

  const SendModal({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.id,
    this.to,
    this.amount,
    this.receiveParams,
  });

  @override
  SendModalState createState() => SendModalState();
}

class SendModalState extends State<SendModal> with TickerProviderStateMixin {
  late WalletLogic _logic;

  late ScrollController _scrollController;

  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;

  final FocusNode nameFocusNode = FocusNode();
  final FocusNode amountFocuseNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final double animationSize = 200;

  bool _isAtTop = true;
  bool _isScanning = true;
  bool _scannerOn = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _logic = widget.walletLogic;

    if (widget.to != null || widget.receiveParams != null) {
      _isScanning = false;
      _scannerOn = false;
    }

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      _scrollController = ModalScrollController.of(context)!;

      onLoad();

      debouncedAddressUpdate = debounce(
        _logic.updateAddress,
        const Duration(milliseconds: 500),
      );

      debouncedAmountUpdate = debounce(
        _logic.updateAmount,
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    //
    _scrollController.removeListener(onScrollUpdate);

    super.dispose();
  }

  void onLoad() async {
    _scrollController.addListener(onScrollUpdate);

    if (widget.id != null) {
      // there is a retry id
      final addr = _logic.addressController.value.text;
      if (addr.isEmpty) {
        return;
      }

      await widget.profilesLogic.getProfile(addr);
    }

    if (widget.to != null) {
      _logic.addressController.text = widget.to ?? '';
      _logic.amountController.text = widget.amount ?? '';

      final profile = await widget.profilesLogic.getProfile(widget.to!);

      _logic.updateAddress(override: profile != null);
      _logic.updateAmount();

      amountFocuseNode.requestFocus();
    }

    if (widget.receiveParams != null) {
      handleScan('/#/?receiveParams=${widget.receiveParams!}');
    }
  }

  void onScrollUpdate() {
    const threshold = 20;
    final isAtTop = _scrollController.position.pixels <= threshold;

    if (!isAtTop && _isAtTop) {
      closeScanner();
    }

    _isAtTop = _scrollController.position.pixels <= threshold;
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    GoRouter.of(context).pop();
  }

  void handleThrottledUpdateAddress(String username) {
    debouncedAddressUpdate();
    widget.profilesLogic.searchProfile(username);
  }

  void handleThrottledUpdateAmount() {
    debouncedAmountUpdate();
  }

  void handleSetMaxAmount() {
    _logic.setMaxAmount();
  }

  void handleSelectProfile(ProfileV1? profile) {
    widget.profilesLogic.selectProfile(profile);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleAddressFieldSubmitted(String? value) {
    final searchedProfile = context.read<ProfilesState>().searchedProfile;
    if (searchedProfile != null) {
      widget.profilesLogic.selectProfile(null);
    }

    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleSend(BuildContext context, String? selectedAddress) async {
    if (_isSending) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final isValid = _logic.validateSendFields(
      _logic.amountController.value.text,
      selectedAddress ?? _logic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    _logic.sendTransaction(
      _logic.amountController.value.text,
      selectedAddress ?? _logic.addressController.value.text,
      message: _logic.messageController.value.text,
      id: widget.id,
    );

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    await Future.delayed(const Duration(milliseconds: 500));

    HapticFeedback.heavyImpact();

    navigator.pop(true);
    return;
  }

  void handleChooseRecipient() async {
    HapticFeedback.heavyImpact();

    final navigator = GoRouter.of(context);

    final shouldDismiss = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (_) => PickeSenderModal(
        walletLogic: _logic,
        profilesLogic: widget.profilesLogic,
        amount: _logic.amountController.value.text,
      ),
    );

    if (shouldDismiss == true) {
      _logic.clearInputControllers();
      _logic.resetInputErrorState();
      widget.profilesLogic.clearSearch();

      await Future.delayed(const Duration(milliseconds: 500));

      HapticFeedback.heavyImpact();

      navigator.pop(true);
    }
  }

  void handleCreateVoucher() async {
    HapticFeedback.heavyImpact();

    final navigator = GoRouter.of(context);

    final wallet = context.read<WalletState>().wallet;

    final shouldDismiss = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (_) => VoucherModal(
        amount: _logic.amountController.value.text,
        symbol: wallet?.symbol,
      ),
    );

    if (shouldDismiss == true) {
      navigator.pop();
    }
  }

  Future<void> closeScanner({focus = true}) async {
    HapticFeedback.lightImpact();

    setState(() {
      _isScanning = false;
    });

    await delay(const Duration(milliseconds: 250));

    HapticFeedback.heavyImpact();

    setState(() {
      _scannerOn = false;
    });

    if (focus) amountFocuseNode.requestFocus();
  }

  Future<void> openScanner() async {
    HapticFeedback.lightImpact();

    setState(() {
      _scannerOn = true;
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    await delay(const Duration(milliseconds: 200));

    HapticFeedback.heavyImpact();

    setState(() {
      _isScanning = true;
    });
  }

  void handleScan(String value) async {
    await closeScanner();

    final hex = await _logic.updateFromCapture(value);

    final profile = await widget.profilesLogic.getProfile(hex ?? '');
    if (profile != null || hex != null) {
      await delay(const Duration(milliseconds: 200));

      amountFocuseNode.requestFocus();
      return;
    }

    await delay(const Duration(milliseconds: 50));

    handleScanAgain(invalid: true);
  }

  void handleScanAgain({bool invalid = false}) async {
    widget.profilesLogic.deSelectProfile();

    _logic.clearAddressController();
    _logic.updateAddress();

    if (invalid) {
      _logic.setInvalidAddress();
    }

    await openScanner();
  }

  void handleEnterManually() {
    closeScanner();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);
    final balance =
        double.tryParse(wallet != null ? wallet.balance : '0.0') ?? 0.0;

    final formattedBalance = formatAmount(
      double.parse(fromDoubleUnit(
        '$balance',
        decimals: wallet?.decimalDigits ?? 2,
      )),
      decimalDigits: 2,
    );

    final invalidScanMessage = context.select(
      (WalletState state) => state.invalidScanMessage,
    );
    final parsingQRAddress = context.select(
      (WalletState state) => state.parsingQRAddress,
    );
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

    final searchLoading = context.select(
      (ProfilesState state) => state.searchLoading,
    );
    final searchError = context.select(
      (ProfilesState state) => state.searchError,
    );

    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );

    final isSendingValid =
        hasAddress && hasAmount && !invalidAmount && !invalidAddress;

    final isValid = (hasAddress &&
            !invalidAddress &&
            invalidScanMessage == null &&
            !parsingQRAddressError &&
            !parsingQRAddress) ||
        selectedProfile != null;

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : height;
    final scannerSize = size * 0.88;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
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
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: ListView(
                        controller: ModalScrollController.of(context),
                        physics: const ScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        scrollDirection: Axis.vertical,
                        children: [
                          const SizedBox(height: 10),
                          if (widget.to == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  height: _isScanning ? scannerSize : 0,
                                  width: scannerSize,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  child: AnimatedOpacity(
                                    opacity: _isScanning ? 1 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: _scannerOn
                                        ? Scanner(
                                            height: scannerSize,
                                            width: scannerSize,
                                            onScan: handleScan,
                                          )
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          if (widget.to == null &&
                              _isScanning &&
                              invalidAddress) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  invalidScanMessage ?? "Invalid QR Code",
                                  style: TextStyle(
                                    color:
                                        ThemeColors.danger.resolveFrom(context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.to == null && _isScanning)
                            const SizedBox(
                              height: 20,
                            ),
                          if (widget.to == null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Button(
                                  text: _isScanning
                                      ? 'Enter Manually'
                                      : 'Scan Again',
                                  color: ThemeColors.surfaceBackground
                                      .resolveFrom(context),
                                  labelColor: ThemeColors.surfaceText
                                      .resolveFrom(context),
                                  suffix: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: Icon(
                                      _isScanning
                                          ? CupertinoIcons.arrow_down
                                          : CupertinoIcons.qrcode,
                                      color: ThemeColors.surfaceText
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  onPressed: _isScanning
                                      ? handleEnterManually
                                      : handleScanAgain,
                                  minWidth: 200,
                                  maxWidth: 200,
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          const Text(
                            'Amount',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: Stack(
                                  children: [
                                    CupertinoTextField(
                                      controller: _logic.amountController,
                                      placeholder: formatCurrency(0.00, ''),
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                      decoration: invalidAmount ||
                                              transactionSendError
                                          ? BoxDecoration(
                                              color: const CupertinoDynamicColor
                                                  .withBrightness(
                                                color: CupertinoColors.white,
                                                darkColor:
                                                    CupertinoColors.black,
                                              ),
                                              border: Border.all(
                                                color: ThemeColors.danger,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(5.0)),
                                            )
                                          : BoxDecoration(
                                              color: const CupertinoDynamicColor
                                                  .withBrightness(
                                                color: CupertinoColors.white,
                                                darkColor:
                                                    CupertinoColors.black,
                                              ),
                                              border: Border.all(
                                                color: hasAmount
                                                    ? ThemeColors.text
                                                        .resolveFrom(context)
                                                    : ThemeColors.transparent
                                                        .resolveFrom(context),
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(5.0)),
                                            ),
                                      maxLines: 1,
                                      maxLength: 25,
                                      focusNode: amountFocuseNode,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: false,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      inputFormatters: [
                                        amountFormatter,
                                      ],
                                      onChanged: (_) =>
                                          handleThrottledUpdateAmount(),
                                      onSubmitted: (_) {
                                        nameFocusNode.requestFocus();
                                      },
                                      prefix: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              10, 0, 10, 0),
                                          child: Text(
                                            wallet?.symbol ?? '',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      suffix: Center(
                                          child: CupertinoButton(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 0, 10, 0),
                                        onPressed: handleSetMaxAmount,
                                        child: const Text(
                                          'max',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.center,
                                        ),
                                      )),
                                    ),
                                    if (_isScanning)
                                      GestureDetector(
                                        onTap: handleEnterManually,
                                        child: Container(
                                          height: 50,
                                          decoration: const BoxDecoration(
                                            color: ThemeColors.transparent,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(5.0)),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (invalidAmount &&
                                  (double.tryParse(_logic
                                              .amountController.value.text) ??
                                          0.0) >
                                      0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Insufficient funds.",
                                      style: TextStyle(
                                        color: ThemeColors.danger
                                            .resolveFrom(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Current balance: ${wallet?.symbol ?? ''} $formattedBalance',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (selectedProfile != null)
                            const Text(
                              'To',
                              style: TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 10),
                          if (isValid)
                            ProfileChip(
                              selectedProfile: selectedProfile,
                              selectedAddress:
                                  _logic.addressController.value.text.isEmpty ||
                                          selectedProfile != null
                                      ? null
                                      : formatHexAddress(
                                          _logic.addressController.value.text),
                              handleDeSelect:
                                  widget.id != null || widget.to != null
                                      ? null
                                      : handleScanAgain,
                            ),
                          const SizedBox(
                            height: 200,
                          ),
                        ],
                      ),
                    ),
                    if (_isSending)
                      Positioned(
                        bottom: 90,
                        child: CupertinoActivityIndicator(
                          color: ThemeColors.subtle.resolveFrom(context),
                        ),
                      ),
                    if (!_isScanning &&
                        !_isSending &&
                        hasAmount &&
                        !invalidAmount)
                      Positioned(
                        bottom: 0,
                        width: width,
                        child: BlurryChild(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color:
                                      ThemeColors.subtle.resolveFrom(context),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              children: (!isSendingValid)
                                  ? [
                                      const SizedBox(height: 10),
                                      Button(
                                        text: 'Choose Recipient',
                                        onPressed: handleChooseRecipient,
                                        minWidth: 200,
                                        maxWidth: 200,
                                      ),
                                      const SizedBox(height: 10),
                                      CupertinoButton(
                                        onPressed: handleCreateVoucher,
                                        child: Text(
                                          'Create Voucher',
                                          style: TextStyle(
                                            color: ThemeColors.text
                                                .resolveFrom(context),
                                            fontSize: 18,
                                            fontWeight: FontWeight.normal,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ]
                                  : [
                                      SlideToComplete(
                                        onCompleted: !_isSending
                                            ? () => handleSend(
                                                  context,
                                                  selectedProfile?.account,
                                                )
                                            : null,
                                        enabled: isSendingValid,
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
                                    ],
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
    );
  }
}
