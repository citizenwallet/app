import 'dart:async';

import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/profile/profile_row.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class PickeSenderModal extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;
  final String amount;
  final bool isMinting;

  const PickeSenderModal({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.amount = '0.0',
    this.isMinting = false,
  });

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

    _logic = widget.walletLogic;

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

    final invalidAddress = context.select(
      (WalletState state) => state.invalidAddress,
    );

    final hasAddress = context.select(
      (WalletState state) => state.hasAddress,
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
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
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
                        Text(
                          AppLocalizations.of(context)!.to,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (!isValid)
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
                                      color: Theme.of(context).colors.danger,
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
                                          ? Theme.of(context)
                                              .colors
                                              .text
                                              .resolveFrom(context)
                                          : Theme.of(context)
                                              .colors
                                              .transparent
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
                                          color: Theme.of(context)
                                              .colors
                                              .subtle
                                              .resolveFrom(context),
                                        ),
                                      )
                                    : Icon(
                                        CupertinoIcons.profile_circled,
                                        color: hasAddress
                                            ? Theme.of(context)
                                                .colors
                                                .text
                                                .resolveFrom(context)
                                            : Theme.of(context)
                                                .colors
                                                .subtleEmphasis
                                                .resolveFrom(context),
                                      ),
                              ),
                            ),
                            onSubmitted: handleAddressFieldSubmitted,
                          ),
                        const SizedBox(height: 10),
                        if (isValid || searchedProfile != null)
                          ProfileChip(
                            selectedProfile: selectedProfile ?? searchedProfile,
                            selectedAddress:
                                _logic.addressController.value.text.isEmpty ||
                                        selectedProfile != null ||
                                        searchedProfile != null
                                    ? null
                                    : formatHexAddress(
                                        _logic.addressController.value.text),
                            handleDeSelect: searchedProfile != null
                                ? null
                                : _logic.addressController.value.text.isEmpty ||
                                        selectedProfile != null ||
                                        searchedProfile != null
                                    ? handleDeSelectProfile
                                    : handleClearAddress,
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
                                        searchedProfile.account ==
                                            profile.account,
                                    onTap: () => handleSelectProfile(profile),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (isValid || searchedProfile != null)
                            const SliverToBoxAdapter(
                              child: SizedBox(
                                height: 90,
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
                        widget.isMinting
                            ? AppLocalizations.of(context)!.mint
                            : AppLocalizations.of(context)!.send,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
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
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: Theme.of(context)
                          .colors
                          .touchable
                          .resolveFrom(context),
                    ),
                  ),
                ),
              ),
              if (_isSending)
                Positioned(
                  bottom: 90,
                  child: CupertinoActivityIndicator(
                    color: Theme.of(context).colors.subtle.resolveFrom(context),
                  ),
                ),
              if (isValid || searchedProfile != null)
                Positioned(
                  bottom: 0,
                  width: width,
                  child: BlurryChild(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Theme.of(context)
                                .colors
                                .subtle
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                      child: Column(
                        children: [
                          SlideToComplete(
                            onCompleted: !_isSending
                                ? widget.isMinting
                                    ? () => handleMint(
                                        context,
                                        selectedProfile?.account ??
                                            searchedProfile?.account)
                                    : () => handleSend(
                                          context,
                                          selectedProfile?.account ??
                                              searchedProfile?.account,
                                        )
                                : null,
                            enabled: isValid || searchedProfile != null,
                            isComplete: _isSending,
                            completionLabel: widget.isMinting
                                ? (_isSending
                                    ? AppLocalizations.of(context)!.minting
                                    : AppLocalizations.of(context)!.mint)
                                : _isSending
                                    ? AppLocalizations.of(context)!.sending
                                    : AppLocalizations.of(context)!.send,
                            thumbColor: Theme.of(context)
                                .colors
                                .surfacePrimary
                                .resolveFrom(context),
                            width: width * 0.6,
                            suffix: isValid || searchedProfile != null
                                ? ProfileCircle(
                                    size: 50,
                                    imageUrl: selectedProfile?.imageSmall ??
                                        searchedProfile?.imageSmall,
                                  )
                                : null,
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.arrow_right,
                                  color: Theme.of(context).colors.white,
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
      ),
    );
  }
}
