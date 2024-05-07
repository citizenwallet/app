import 'dart:async';

import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/profile/profile_row.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendSelectionModal extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;
  final String amount;
  final bool isMinting;

  const SendSelectionModal({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.amount = '0.0',
    this.isMinting = false,
  });

  @override
  SendSelectionModalState createState() => SendSelectionModalState();
}

class SendSelectionModalState extends State<SendSelectionModal>
    with TickerProviderStateMixin {
  late WalletLogic _logic;
  late ProfilesLogic _profilesLogic;
  late VoucherLogic _voucherLogic;

  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;

  final FocusNode nameFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final double animationSize = 200;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _logic = widget.walletLogic;
    _profilesLogic = ProfilesLogic(context);
    _voucherLogic = VoucherLogic(context);

    WidgetsBinding.instance.addObserver(_profilesLogic);
    WidgetsBinding.instance.addObserver(_voucherLogic);
    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

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

  void handleScanQr() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await GoRouter.of(context).push<bool?>(
      '/scanQrModal',
      extra: {
        'logic': _logic,
        'profilesLogic': _profilesLogic,
      },
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  void handleSendViaLink() async {
    HapticFeedback.lightImpact();

    _logic.pauseFetching();
    _profilesLogic.pause();
    _voucherLogic.pause();

    await GoRouter.of(context).push<bool?>(
      '/sendViaLink',
      extra: {
        'logic': _logic,
        'profilesLogic': _profilesLogic,
      },
    );

    _logic.resumeFetching();
    _profilesLogic.resume();
    _voucherLogic.resume();
  }

  @override
  void dispose() {
    //
    super.dispose();
  }

  void onLoad() async {
    widget.profilesLogic.allProfiles();
    _logic.updateAddress();

    nameFocusNode.requestFocus();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

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
    _logic.updateAddress(override: profile != null);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleDeSelectProfile() {
    widget.profilesLogic.deSelectProfile();
    _logic.updateAddress();
    nameFocusNode.requestFocus();
  }

  void handleClearAddress() {
    _logic.clearInputControllers();
    _logic.updateAddress();
    nameFocusNode.requestFocus();
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
      widget.amount,
      selectedAddress ?? _logic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    _logic.sendTransaction(
      widget.amount,
      selectedAddress ?? _logic.addressController.value.text,
      message: _logic.messageController.value.text,
    );

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    await Future.delayed(const Duration(milliseconds: 500));

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
      widget.amount,
      selectedAddress ?? _logic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    _logic.mintTokens(
      widget.amount,
      selectedAddress ?? _logic.addressController.value.text,
    );

    _logic.clearInputControllers();
    _logic.resetInputErrorState();
    widget.profilesLogic.clearSearch();

    await Future.delayed(const Duration(milliseconds: 500));

    HapticFeedback.heavyImpact();

    navigator.pop(true);
    return;
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

    final profileSuggestions = context.select(selectProfileSuggestions);
    final searchLoading = context.select(
      (ProfilesState state) => state.searchLoading,
    );

    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );

    final searchedProfile = context.select(
      (ProfilesState state) => state.searchedProfile,
    );

    final isValid = (hasAddress &&
            _logic.addressController.value.text.startsWith('0x') &&
            _logic.addressController.value.text.length == 42) ||
        selectedProfile != null;

    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.background.resolveFrom(context),
        child: SafeArea(
          bottom: false,
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 0),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Flex(
                direction: Axis.vertical,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              onPressed: handleSendViaLink,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  // border: Border.all(
                                  //   color: ThemeColors.surfacePrimary
                                  //       .resolveFrom(context),
                                  //   width: 2,
                                  // ),
                                ),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Icon(
                                    CupertinoIcons.link,
                                    color: ThemeColors.surfacePrimary
                                        .resolveFrom(context),
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: 250,
                              height: 40,
                              child: const Text(
                                "Send via link",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.black,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              onPressed: handleScanQr,
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Icon(
                                    CupertinoIcons.qrcode_viewfinder,
                                    color: ThemeColors.surfacePrimary
                                        .resolveFrom(context),
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              width: 250,
                              height: 40,
                              child: const Text(
                                "Scan QR Code",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.black,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
