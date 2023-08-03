import 'dart:async';

import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
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
import 'package:citizenwallet/widgets/profile/profile_badge.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/scanner/scanner.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class SendModal extends StatefulWidget {
  final ProfilesLogic profilesLogic;

  final String? id;
  final String? to;

  const SendModal({
    Key? key,
    required this.profilesLogic,
    this.id,
    this.to,
  }) : super(key: key);

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

  bool _isAmountFocused = false;

  @override
  void initState() {
    super.initState();

    _logic = WalletLogic(context);

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
    amountFocuseNode.removeListener(handleAmountFocus);

    super.dispose();
  }

  void onLoad() async {
    _scrollController.addListener(onScrollUpdate);
    amountFocuseNode.addListener(handleAmountFocus);

    if (widget.id != null) {
      // there is a retry id
      final addr = _logic.addressController.value.text;
      if (addr.isEmpty) {
        return;
      }

      await widget.profilesLogic.getProfile(addr);
    }

    if (widget.to != null) {
      await widget.profilesLogic.getProfile(widget.to!);
    }
  }

  void onScrollUpdate() {
    if (_isAtTop) {
      return;
    }

    const qrScannerHeight = 200;

    if (_scrollController.position.pixels <= qrScannerHeight) {
      setState(() {
        _isAtTop = true;
      });
    }
  }

  void handleAmountFocus() {
    if (!_isAmountFocused && amountFocuseNode.hasFocus) {
      closeScanner();
    }

    _isAmountFocused = amountFocuseNode.hasFocus;
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

  void handleQRScan() async {
    final result = await showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (_) => const ScannerModal(
        modalKey: 'send-form-anything-scanner',
      ),
    );

    if (result != null) {
      _logic.updateFromCapture(result);

      final addr = _logic.addressController.value.text;
      if (addr.isEmpty) {
        return;
      }

      final profile = await widget.profilesLogic.getProfile(addr);
      if (profile != null) {
        _logic.addressController.text = profile.username;
      }

      amountFocuseNode.requestFocus();
    }
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

  Future<void> closeScanner() async {
    setState(() {
      _isScanning = false;
    });

    await delay(const Duration(milliseconds: 250));

    setState(() {
      _scannerOn = false;
    });
  }

  Future<void> openScanner() async {
    setState(() {
      _scannerOn = true;
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );

    await delay(const Duration(milliseconds: 200));

    setState(() {
      _isScanning = true;
    });
  }

  void handleScan(String value) async {
    await closeScanner();

    final hex = _logic.updateFromCapture(value);

    final profile = await widget.profilesLogic.getProfile(hex ?? '');
    if (profile != null) {
      amountFocuseNode.requestFocus();
      return;
    }

    await delay(const Duration(milliseconds: 50));

    handleScanAgain();
  }

  void handleScanAgain() async {
    widget.profilesLogic.deSelectProfile();

    await openScanner();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);
    final balance =
        double.tryParse(wallet != null ? wallet.balance : '0.0') ?? 0.0;
    final formattedBalance = formatAmount(
      balance,
      decimalDigits: wallet != null ? wallet.decimalDigits : 2,
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
                          if (_isScanning && !searchLoading && searchError) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Invalid QR Code",
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _isScanning ? 0 : 1,
                                duration: const Duration(milliseconds: 250),
                                child: Button(
                                  text: 'Scan Again',
                                  color: ThemeColors.surfaceBackground
                                      .resolveFrom(context),
                                  labelColor: ThemeColors.surfaceText
                                      .resolveFrom(context),
                                  suffix: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: Icon(
                                      CupertinoIcons.qrcode,
                                      color: ThemeColors.surfaceText
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  onPressed: handleScanAgain,
                                  minWidth: 200,
                                  maxWidth: 200,
                                ),
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
                                child: CupertinoTextField(
                                  controller: _logic.amountController,
                                  placeholder: formatCurrency(1050.00, ''),
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
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
                                  decoration: invalidAmount ||
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
                                            color: hasAmount
                                                ? ThemeColors.text
                                                    .resolveFrom(context)
                                                : ThemeColors.transparent
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
                                'Current balance: $formattedBalance ${wallet?.symbol ?? ''}',
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
                          if (selectedProfile != null)
                            ProfileChip(
                              selectedProfile: selectedProfile,
                              handleDeSelect: handleScanAgain,
                            ),
                          // if (selectedProfile == null)
                          //   CupertinoTextField(
                          //     controller: _logic.addressController,
                          //     placeholder: '@username or 0xaddress',
                          //     maxLines: 1,
                          //     autocorrect: false,
                          //     enableSuggestions: false,
                          //     focusNode: nameFocusNode,
                          //     textInputAction: TextInputAction.next,
                          //     onChanged: handleThrottledUpdateAddress,
                          //     decoration: invalidAddress ||
                          //             parsingQRAddressError ||
                          //             transactionSendError
                          //         ? BoxDecoration(
                          //             color: const CupertinoDynamicColor
                          //                 .withBrightness(
                          //               color: CupertinoColors.white,
                          //               darkColor: CupertinoColors.black,
                          //             ),
                          //             border: Border.all(
                          //               color: ThemeColors.danger,
                          //             ),
                          //             borderRadius: const BorderRadius.all(
                          //                 Radius.circular(5.0)),
                          //           )
                          //         : BoxDecoration(
                          //             color: const CupertinoDynamicColor
                          //                 .withBrightness(
                          //               color: CupertinoColors.white,
                          //               darkColor: CupertinoColors.black,
                          //             ),
                          //             border: Border.all(
                          //               color: hasAddress
                          //                   ? ThemeColors.text
                          //                       .resolveFrom(context)
                          //                   : ThemeColors.transparent
                          //                       .resolveFrom(context),
                          //             ),
                          //             borderRadius: const BorderRadius.all(
                          //                 Radius.circular(5.0)),
                          //           ),
                          //     prefix: Center(
                          //       child: Padding(
                          //         padding:
                          //             const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          //         child: searchLoading
                          //             ? SizedBox(
                          //                 height: 20,
                          //                 width: 24,
                          //                 child: CupertinoActivityIndicator(
                          //                   color: ThemeColors.subtle
                          //                       .resolveFrom(context),
                          //                 ),
                          //               )
                          //             : Icon(
                          //                 CupertinoIcons.profile_circled,
                          //                 color: hasAddress
                          //                     ? ThemeColors.text
                          //                         .resolveFrom(context)
                          //                     : ThemeColors.subtleEmphasis
                          //                         .resolveFrom(context),
                          //               ),
                          //       ),
                          //     ),
                          //     suffix: GestureDetector(
                          //       onTap: handleQRScan,
                          //       child: Center(
                          //         child: Padding(
                          //           padding:
                          //               const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          //           child: Icon(
                          //             CupertinoIcons.qrcode,
                          //             color: ThemeColors.primary
                          //                 .resolveFrom(context),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //     onSubmitted: handleAddressFieldSubmitted,
                          //   ),
                          // const SizedBox(height: 20),
                          // const Text(
                          //   'Description',
                          //   style: TextStyle(
                          //       fontSize: 24, fontWeight: FontWeight.bold),
                          // ),
                          // const SizedBox(height: 10),
                          // CupertinoTextField(
                          //   controller: _logic.messageController,
                          //   placeholder: 'Enter a description',
                          //   maxLines: 4,
                          //   maxLength: 256,
                          //   focusNode: messageFocusNode,
                          // ),
                          const SizedBox(
                            height: 60,
                          ),
                          if (selectedProfile == null)
                            _isSending
                                ? CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  )
                                : Column(
                                    children: [
                                      Button(
                                        text: 'Chooose Recipient',
                                        onPressed: () => print('recipient'),
                                        minWidth: 200,
                                        maxWidth: 200,
                                      ),
                                      const SizedBox(height: 10),
                                      CupertinoButton(
                                        onPressed: () =>
                                            print('create voucher'),
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
                                    ],
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
                    if (selectedProfile != null)
                      Positioned(
                        bottom: 0,
                        child: SizedBox(
                          height: 90,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                            child: SlideToComplete(
                              onCompleted: !_isSending
                                  ? () => handleSend(
                                        context,
                                        selectedProfile.account,
                                      )
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
    );
  }
}
