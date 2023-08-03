import 'dart:async';

import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
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

class PickeSenderModal extends StatefulWidget {
  final ProfilesLogic profilesLogic;
  final String amount;

  const PickeSenderModal({
    Key? key,
    required this.profilesLogic,
    this.amount = '0.0',
  }) : super(key: key);

  @override
  PickeSenderModalState createState() => PickeSenderModalState();
}

class PickeSenderModalState extends State<PickeSenderModal>
    with TickerProviderStateMixin {
  late WalletLogic _logic;

  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;

  final FocusNode nameFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final double animationSize = 200;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _logic = WalletLogic(context);

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

    final isValid = (hasAddress && !invalidAddress) || selectedProfile != null;

    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Flex(
                direction: Axis.vertical,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        const Text(
                          'To',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (selectedProfile != null)
                          ProfileChip(
                            selectedProfile: selectedProfile,
                            handleDeSelect: handleDeSelectProfile,
                          ),
                        if (selectedProfile == null)
                          CupertinoTextField(
                            controller: _logic.addressController,
                            placeholder: '@username or 0xaddress',
                            maxLines: 1,
                            autocorrect: false,
                            enableSuggestions: false,
                            focusNode: nameFocusNode,
                            textInputAction: TextInputAction.next,
                            onChanged: handleThrottledUpdateAddress,
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
                                      color: hasAddress
                                          ? ThemeColors.text
                                              .resolveFrom(context)
                                          : ThemeColors.transparent
                                              .resolveFrom(context),
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(5.0)),
                                  ),
                            prefix: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 0, 10, 0),
                                child: searchLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 24,
                                        child: CupertinoActivityIndicator(
                                          color: ThemeColors.subtle
                                              .resolveFrom(context),
                                        ),
                                      )
                                    : Icon(
                                        CupertinoIcons.profile_circled,
                                        color: hasAddress
                                            ? ThemeColors.text
                                                .resolveFrom(context)
                                            : ThemeColors.subtleEmphasis
                                                .resolveFrom(context),
                                      ),
                              ),
                            ),
                            onSubmitted: handleAddressFieldSubmitted,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: CustomScrollView(
                        controller: ModalScrollController.of(context),
                        scrollBehavior: const CupertinoScrollBehavior(),
                        scrollDirection: Axis.vertical,
                        slivers: [
                          const SliverToBoxAdapter(
                            child: SizedBox(
                              height: 20,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: profileSuggestions.length,
                              (context, index) {
                                final profile = profileSuggestions[index];

                                return Padding(
                                  key: Key(profile.account),
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                  child: ProfileRow(
                                    profile: profile,
                                    loading: false,
                                    active: searchedProfile != null &&
                                        searchedProfile == profile,
                                    onTap: () => handleSelectProfile(profile),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  titleWidget: Row(
                    children: [
                      Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${wallet?.symbol} ${widget.amount}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
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
              if (_isSending)
                Positioned(
                  bottom: 90,
                  child: CupertinoActivityIndicator(
                    color: ThemeColors.subtle.resolveFrom(context),
                  ),
                ),
              if (isValid)
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
                                  selectedProfile?.account,
                                )
                            : null,
                        enabled: isValid,
                        isComplete: _isSending,
                        completionLabel: _isSending ? 'Sending...' : 'Send',
                        thumbColor:
                            ThemeColors.surfacePrimary.resolveFrom(context),
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
      ),
    );
  }
}
