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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendScannerModal extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;

  final String? id;
  final String? to;
  final String? amount;
  final String? message;

  final String? receiveParams;

  final bool isMinting;

  const SendScannerModal({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.id,
    this.to,
    this.amount,
    this.message,
    this.receiveParams,
    this.isMinting = false,
  });

  @override
  SendScannerModalState createState() => SendScannerModalState();
}

class SendScannerModalState extends State<SendScannerModal> with TickerProviderStateMixin {
  late WalletLogic _logic;

  late ScrollController _scrollController;

  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;

  final FocusNode amountFocuseNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();
  final IntegerAmountFormatter integerAmountFormatter =
      IntegerAmountFormatter();

  final double animationSize = 200;

  bool _isAtTop = true;
  bool _isScanning = true;
  bool _scannerOn = true;
  bool _isSending = false;
  bool _isDescribing = false;

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
    _logic.stopListeningMessage();
    messageFocusNode.removeListener(handleMessageListenerUpdate);

    super.dispose();
  }

  void onLoad() async {
    _scrollController.addListener(onScrollUpdate);
    _logic.startListeningMessage();
    messageFocusNode.addListener(handleMessageListenerUpdate);

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
      _logic.messageController.text = widget.message ?? '';
      _logic.updateMessage();
      _logic.updateListenerAmount();

      final profile = await widget.profilesLogic.getProfile(widget.to!);

      _logic.updateAddress(override: profile != null);
      _logic.updateAmount();

      amountFocuseNode.requestFocus();
    }

    if (widget.receiveParams != null) {
      handleScan('/#/?receiveParams=${widget.receiveParams!}');
    }
  }

  void handleMessageListenerUpdate() {
    if (!messageFocusNode.hasFocus) {
      handleDescribeDone();
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

  void handleDescribe() async {
    setState(() {
      _isDescribing = true;
    });

    await delay(const Duration(milliseconds: 50));

    messageFocusNode.requestFocus();
  }

  void handleDescribeDone() {
    setState(() {
      _isDescribing = false;
    });
  }

  void handleCloseDescribe() {
    handleDescribeDone();

    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleClearDescribe() {
    _logic.messageController.clear();

    _logic.updateMessage();
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
      message: _logic.messageController.value.text.trim(),
      id: widget.id,
    );

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    navigator.pop(true);
    return;
  }

  void handleMint(BuildContext context, String? selectedAddress) async {
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

    _logic.mintTokens(
      _logic.amountController.value.text,
      selectedAddress ?? _logic.addressController.value.text,
    );

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    await Future.delayed(const Duration(milliseconds: 50));

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
        isMinting: widget.isMinting,
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

    final name = _logic.messageController.value.text.trim().isEmpty
        ? null
        : _logic.messageController.value.text;

    final shouldDismiss = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (_) => VoucherModal(
        amount: _logic.amountController.value.text,
        symbol: wallet?.symbol,
        name: name,
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

    final message = context.select(
      (WalletState state) => state.message,
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
        backgroundColor: ThemeColors.background.resolveFrom(context),
        child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Header(
                    color: ThemeColors.background,
                    titleWidget: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              widget.isMinting
                                  ? AppLocalizations.of(context)!.mint
                                  : AppLocalizations.of(context)!.send,
                              style: TextStyle(
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
                  )),
              const SizedBox(height: 20),
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
                                  invalidScanMessage ??
                                      AppLocalizations.of(context)!
                                          .invalidQRCode,
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
                        ],
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
