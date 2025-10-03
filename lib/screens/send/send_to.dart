// import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/models/send_transaction.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/selectors.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/state/scan/logic.dart';
import 'package:citizenwallet/state/scan/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/profile/profile_row.dart';
import 'package:citizenwallet/widgets/scanner/nfc_modal.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:flutter_svg/svg.dart';

class SendToScreen extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;
  final VoucherLogic? voucherLogic;
  final String? sendToURL;
  final SendTransaction? sendTransaction;

  final bool isMinting;

  const SendToScreen({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.voucherLogic,
    this.isMinting = false,
    this.sendToURL,
    this.sendTransaction,
  });

  @override
  State<SendToScreen> createState() => _SendToScreenState();
}

class _SendToScreenState extends State<SendToScreen> {
  final nameFocusNode = FocusNode();
  final ScanLogic _scanLogic = ScanLogic();
  String? _currentSendToURL;
  final _scrollController = ScrollController();
  // late SendTransaction _sendTransaction;

  late void Function() debouncedAddressUpdate;

  @override
  void initState() {
    super.initState();
    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      final walletLogic = widget.walletLogic;

      onLoad();

      debouncedAddressUpdate = debounce(
        walletLogic.updateAddress,
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    nameFocusNode.dispose();
    _scrollController.dispose();

    _currentSendToURL = null;

    final walletLogic = widget.walletLogic;
    final profilesLogic = widget.profilesLogic;

    profilesLogic.clearSearch(notify: false);
    _scanLogic.cancelScan(notify: false);

    walletLogic.clearDeepLinkRouteState();

    super.dispose();
  }

  @override
  void didUpdateWidget(SendToScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only handle selection if sendToURL is new and we haven't processed it yet
    if (widget.sendToURL != null &&
        widget.sendToURL != oldWidget.sendToURL &&
        widget.sendToURL != _currentSendToURL) {
      _currentSendToURL = widget.sendToURL;
      handleParseQRCode(context, widget.sendToURL!);
    }
  }

  void onLoad() async {
    _scanLogic.init(context);
    _scanLogic.load();

    await delay(const Duration(milliseconds: 250));

    final walletLogic = widget.walletLogic;
    final profilesLogic = widget.profilesLogic;

    if (walletLogic.config != null &&
        walletLogic.credentials != null &&
        walletLogic.accountAddress != null) {
      profilesLogic.setWalletState(
        walletLogic.config!,
        walletLogic.credentials!,
        walletLogic.accountAddress!,
      );
    }

    profilesLogic.clearSearch();
    await profilesLogic.allProfiles();
    walletLogic.updateAddress();

    nameFocusNode.requestFocus();

    isSendToURLAvailable();
  }

  void isSendToURLAvailable() {
    if (widget.sendToURL != null && widget.sendToURL != _currentSendToURL) {
      _currentSendToURL = widget.sendToURL;
      handleParseQRCode(context, widget.sendToURL!);
    }
  }

  void handleThrottledUpdateAddress(String value) {
    final profilesLogic = widget.profilesLogic;
    final walletLogic = widget.walletLogic;

    debouncedAddressUpdate();

    if (walletLogic.config != null &&
        walletLogic.credentials != null &&
        walletLogic.accountAddress != null) {
      profilesLogic.searchProfile(value);
    }
  }

  void handleAddressFieldSubmitted(String value) {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void handleSendLink(BuildContext context) async {
    final walletLogic = widget.walletLogic;

    final profilesLogic = widget.profilesLogic;

    profilesLogic.clearSearch(notify: false);

    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    if (!context.mounted) {
      return;
    }

    final navigator = GoRouter.of(context);

    final address = await navigator
        .push<String?>('/wallet/${walletLogic.account}/send/link', extra: {
      'walletLogic': walletLogic,
      'profilesLogic': profilesLogic,
      'voucherLogic': widget.voucherLogic,
      'isMinting': widget.isMinting,
    });

    if (address != null) {
      navigator.pop(true);
    }

    onLoad();
  }

  void handleScanQRCode(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ScannerModal(
        modalKey: 'send-qr-scanner',
      ),
    );

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    handleDismissSelection();

    handleParseQRCode(context, result);
  }

  void handleReadNFC(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const NFCModal(
        modalKey: 'send-nfc-scanner',
      ),
    );

    // the iOS NFC Modal sets the app to inactive and then resumes it
    // this causes transactions to start being requested again
    // this is a workaround to wait for the app to resume before pausing the fetching
    if (isPlatformApple()) {
      // iOS needs an extra delay which is the time it takes to close the NFC modal
      delay(const Duration(seconds: 1)).then((_) {
        widget.walletLogic.pauseFetching();
      });
    }

    widget.walletLogic.pauseFetching();

    if (result == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    handleDismissSelection();

    handleParseQRCode(context, result);
  }

  void handleParseQRCode(
    BuildContext context,
    String result,
  ) async {
    final walletLogic = widget.walletLogic;

    final hex = await walletLogic.updateFromCapture(result);
    if (hex == null) {
      return;
    }

    widget.profilesLogic.getLocalProfile(hex);

    if (!context.mounted) {
      return;
    }

    handleSetAmount(
      context,
      account: hex,
    );
  }

  void handleSelectProfile(BuildContext context, ProfileV1? profile) async {
    if (profile == null) {
      return;
    }

    final walletLogic = widget.walletLogic;
    final profilesLogic = widget.profilesLogic;

    profilesLogic.selectProfile(profile);
    walletLogic.updateAddress(override: true);
    FocusManager.instance.primaryFocus?.unfocus();

    if (!context.mounted) {
      return;
    }

    handleSetAmount(context, account: profile.account);
  }

  void handleSetAmount(
    BuildContext context, {
    String? account,
  }) async {
    final walletLogic = widget.walletLogic;

    final selectedProfile = context.read<ProfilesState>().selectedProfile;

    final toAccount = account ??
        selectedProfile?.account ??
        walletLogic.addressController.value.text;

    if (toAccount.isEmpty) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    if (!context.mounted) {
      return;
    }

    final profilesLogic = widget.profilesLogic;

    final navigator = GoRouter.of(context);

    final sent = await navigator.push(
      '/wallet/${walletLogic.account}/send/$toAccount',
      extra: {
        'walletLogic': walletLogic,
        'profilesLogic': profilesLogic,
        'isMinting': widget.isMinting,
      },
    );

    if (sent == true) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (navigator.canPop()) {
        navigator.pop(true);
      } else {
        navigator.go('/wallet/${walletLogic.account}');
      }
      return;
    }

    onLoad();
  }

  void handleDismissSelection() async {
    final walletLogic = widget.walletLogic;
    widget.profilesLogic.deSelectProfile();

    walletLogic.clearAddressController();
    walletLogic.updateAddress();

    nameFocusNode.requestFocus();
  }

  void handleScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final walletLogic = widget.walletLogic;

    final invalidAddress = context.select(
      (WalletState state) => state.invalidAddress,
    );

    final config = context.select(
      (WalletState state) => state.config,
    );

    final hasAddress = context.select(
      (WalletState state) => state.hasAddress,
    );

    final searchLoading = context.select(
      (ProfilesState state) => state.searchLoading,
    );

    final parsingQRAddressError = context.select(
      (WalletState state) => state.parsingQRAddressError,
    );

    final profileSuggestions = context.select(selectProfileSuggestions);

    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );

    final scanStatus = context.select(
      (ScanState state) => state,
    );

    final bool noAccountFound = profileSuggestions.isEmpty &&
        walletLogic.addressController.value.text.isNotEmpty &&
        !isEthAddress(walletLogic.addressController.value.text);

    final bool displayScanNfc = config != null &&
        config.hasCards() &&
        scanStatus.status != ScanStateType.notAvailable &&
        scanStatus.status != ScanStateType.notReady;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          bottom: false,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  title: widget.isMinting
                      ? AppLocalizations.of(context)!.mint
                      : AppLocalizations.of(context)!.send,
                  showBackButton: true,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          floating: false,
                          delegate: PersistentHeaderDelegate(
                            expandedHeight: displayScanNfc ? 220 : 180,
                            minHeight: 110,
                            builder: (context, shrink) => GestureDetector(
                              onTap: handleScrollToTop,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      height: 110,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [0.5, 1.0],
                                          colors: [
                                            Theme.of(context)
                                                .colors
                                                .uiBackgroundAlt
                                                .resolveFrom(context),
                                            Theme.of(context)
                                                .colors
                                                .uiBackgroundAlt
                                                .resolveFrom(context)
                                                .withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: displayScanNfc ? 100 : 50,
                                    left: 20,
                                    right: 20,
                                    child: Opacity(
                                      opacity: progressiveClamp(
                                        0,
                                        1,
                                        shrink * 4,
                                      ),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: () =>
                                            handleSendLink(context),
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.link,
                                                color: Theme.of(context)
                                                    .colors
                                                    .primary
                                                    .resolveFrom(context),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .sendViaLink,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .primary
                                                      .resolveFrom(context),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: displayScanNfc ? 50 : 0,
                                    left: 20,
                                    right: 20,
                                    child: Opacity(
                                      opacity: progressiveClamp(
                                        0,
                                        1,
                                        shrink * 2,
                                      ),
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(5),
                                        onPressed: () =>
                                            handleScanQRCode(context),
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons
                                                    .qrcode_viewfinder,
                                                color: Theme.of(context)
                                                    .colors
                                                    .primary
                                                    .resolveFrom(context),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .scanQRCode,
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .primary
                                                      .resolveFrom(context),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (displayScanNfc)
                                    Positioned(
                                      bottom: 0,
                                      left: 20,
                                      right: 20,
                                      child: Opacity(
                                        opacity: progressiveClamp(
                                          0,
                                          1,
                                          shrink * 2,
                                        ),
                                        child: CupertinoButton(
                                          padding: const EdgeInsets.all(5),
                                          onPressed: () =>
                                              handleReadNFC(context),
                                          child: Container(
                                            height: 50,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  'assets/icons/contactless.svg',
                                                  semanticsLabel:
                                                      'contactless icon',
                                                  height: 24,
                                                  width: 24,
                                                  color: Theme.of(context)
                                                      .colors
                                                      .primary
                                                      .resolveFrom(context),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  AppLocalizations.of(context)!
                                                      .sendToNFCTag,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colors
                                                        .primary
                                                        .resolveFrom(context),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (selectedProfile != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: ProfileChip(
                                        selectedProfile: selectedProfile,
                                        handleDeSelect: handleDismissSelection,
                                      ),
                                    ),
                                  if (selectedProfile == null)
                                    Container(
                                      height: 50,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(25),
                                        child: CupertinoTextField(
                                          controller:
                                              walletLogic.addressController,
                                          placeholder:
                                              AppLocalizations.of(context)!
                                                  .searchUserAndAddress,
                                          maxLines: 1,
                                          autocorrect: false,
                                          enableSuggestions: false,
                                          focusNode: nameFocusNode,
                                          textInputAction: TextInputAction.done,
                                          onChanged:
                                              handleThrottledUpdateAddress,
                                          decoration: invalidAddress ||
                                                  parsingQRAddressError
                                              ? BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .subtle
                                                      .resolveFrom(context),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colors
                                                        .danger,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                )
                                              : BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colors
                                                      .subtle
                                                      .resolveFrom(context),
                                                  border: Border.all(
                                                    color: hasAddress
                                                        ? Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context)
                                                        : Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                          prefix: const SizedBox(
                                            width: 10,
                                          ),
                                          suffix: Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                10,
                                                0,
                                                20,
                                                0,
                                              ),
                                              child: searchLoading
                                                  ? SizedBox(
                                                      height: 20,
                                                      width: 24,
                                                      child:
                                                          CupertinoActivityIndicator(
                                                        color: Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context),
                                                      ),
                                                    )
                                                  : Icon(
                                                      CupertinoIcons.search,
                                                      color: Theme.of(context)
                                                          .colors
                                                          .primary
                                                          .resolveFrom(context),
                                                    ),
                                            ),
                                          ),
                                          onSubmitted:
                                              handleAddressFieldSubmitted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 20,
                          ),
                        ),
                        if (noAccountFound)
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.search,
                                    color: Theme.of(context)
                                        .colors
                                        .subtleEmphasis
                                        .resolveFrom(context),
                                    size: 100,
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .accountNotFound,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colors
                                          .subtleSolid
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!noAccountFound)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: profileSuggestions.length,
                              (context, index) {
                                final profile = profileSuggestions[index];

                                return Padding(
                                  key: Key(profile.account),
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                  child: ProfileRow(
                                    profile: profile,
                                    loading: false,
                                    onTap: () =>
                                        handleSelectProfile(context, profile),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context)
                                  .withOpacity(0.0),
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!invalidAddress && hasAddress)
                      Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Button(
                              text: AppLocalizations.of(context)!.enteramount,
                              labelColor: Theme.of(context)
                                  .colors
                                  .white
                                  .resolveFrom(context),
                              onPressed: () => handleSetAmount(context),
                              minWidth: 200,
                              maxWidth: width - 60,
                            ),
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
