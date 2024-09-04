import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class SendDetailsScreen extends StatefulWidget {
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;
  final VoucherLogic? voucherLogic;

  final bool isMinting;
  final bool isLink;

  const SendDetailsScreen({
    super.key,
    required this.walletLogic,
    required this.profilesLogic,
    this.voucherLogic,
    this.isMinting = false,
    this.isLink = false,
  });

  @override
  State<SendDetailsScreen> createState() => _SendDetailsScreenState();
}

class _SendDetailsScreenState extends State<SendDetailsScreen> {
  final FocusNode amountFocusNode = FocusNode();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();
  final IntegerAmountFormatter integerAmountFormatter =
      IntegerAmountFormatter();

  final _scrollController = ScrollController();

  late void Function() debouncedAmountUpdate;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      final walletLogic = widget.walletLogic;

      onLoad();

      debouncedAmountUpdate = debounce(
        () => walletLogic.updateAmount(unlimited: widget.isMinting),
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  void dispose() {
    amountFocusNode.dispose();
    _scrollController.dispose();

    final walletLogic = widget.walletLogic;

    walletLogic.clearAmountController();
    walletLogic.resetInputErrorState();

    super.dispose();
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    amountFocusNode.requestFocus();
  }

  void handleThrottledUpdateAmount() {
    debouncedAmountUpdate();
  }

  void handleSetMaxAmount() {
    final walletLogic = widget.walletLogic;

    walletLogic.setMaxAmount();
  }

  void handleCreateVoucher(BuildContext context, String symbol) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final voucherLogic = widget.voucherLogic;
    if (voucherLogic == null) {
      return;
    }

    final walletLogic = widget.walletLogic;

    voucherLogic.createVoucher(
      balance: widget.walletLogic.amountController.value.text,
      symbol: symbol,
    );

    voucherLogic.shareReady();

    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    if (!context.mounted) {
      return;
    }

    final navigator = GoRouter.of(context);

    final sent = await navigator.push<bool?>(
        '/wallet/${walletLogic.account}/send/link/progress',
        extra: {
          'voucherLogic': voucherLogic,
        });

    if (sent == true) {
      navigator.pop(true);
      return;
    }

    setState(() {
      _isSending = false;
    });

    return;
  }

  void handleSend(BuildContext context, String? selectedAddress) async {
    if (_isSending) {
      return;
    }

    final walletLogic = widget.walletLogic;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final isValid = walletLogic.validateSendFields(
      walletLogic.amountController.value.text,
      selectedAddress ?? walletLogic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    final toAccount =
        selectedAddress ?? walletLogic.addressController.value.text;

    walletLogic.sendTransaction(
      walletLogic.amountController.value.text,
      selectedAddress ?? walletLogic.addressController.value.text,
      message: walletLogic.messageController.value.text.trim(),
    );

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    final sent = await navigator
        .push<bool?>('/wallet/${walletLogic.account}/send/$toAccount/progress');

    if (sent == true) {
      walletLogic.clearInputControllers();
      walletLogic.resetInputErrorState();
      widget.profilesLogic.clearSearch();

      navigator.pop(true);
      return;
    }

    setState(() {
      _isSending = false;
    });

    return;
  }

  void handleMint(BuildContext context, String? selectedAddress) async {
    if (_isSending) {
      return;
    }

    final walletLogic = widget.walletLogic;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final isValid = walletLogic.validateSendFields(
      walletLogic.amountController.value.text,
      selectedAddress ?? walletLogic.addressController.value.text,
    );

    if (!isValid) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    final toAccount =
        selectedAddress ?? walletLogic.addressController.value.text;

    walletLogic.mintTokens(
      walletLogic.amountController.value.text,
      toAccount,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    final sent = await navigator
        .push<bool?>('/wallet/${walletLogic.account}/send/$toAccount/progress');

    if (sent == true) {
      walletLogic.clearInputControllers();
      walletLogic.resetInputErrorState();
      widget.profilesLogic.clearSearch();

      navigator.pop(true);
      return;
    }

    setState(() {
      _isSending = false;
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    const double profileCircleSize = 48;

    final walletLogic = widget.walletLogic;

    final wallet = context.select(
      (WalletState state) => state.wallet,
    );
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

    final hasAddress = context.select(
      (WalletState state) => state.hasAddress,
    );

    final hasAmount = context.select(
      (WalletState state) => state.hasAmount,
    );

    final invalidAmount = context.select(
      (WalletState state) => state.invalidAmount,
    );

    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );

    final searchedProfile = context.select(
      (ProfilesState state) => state.searchedProfile,
    );

    final isLink = widget.isLink;

    final isValid = (hasAddress &&
            walletLogic.addressController.value.text.startsWith('0x') &&
            walletLogic.addressController.value.text.length == 42) ||
        selectedProfile != null;

    final isSendingValid = (hasAddress || isLink) &&
        hasAmount &&
        !invalidAmount &&
        (!invalidAddress || isLink);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
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
                    ListView(
                      physics:
                          const ScrollPhysics(parent: BouncingScrollPhysics()),
                      scrollDirection: Axis.vertical,
                      children: [
                        if (selectedProfile != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ProfileCircle(
                                size: profileCircleSize,
                                backgroundColor: Theme.of(context)
                                    .colors
                                    .uiBackgroundAlt
                                    .resolveFrom(context),
                                imageUrl: selectedProfile.imageSmall,
                              ),
                               const SizedBox(width: 8), 
                              Text(
                                selectedProfile.name.isNotEmpty
                                    ? selectedProfile.name
                                    : AppLocalizations.of(context)!.anonymous,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: CupertinoTextField(
                            controller: walletLogic.amountController,
                            placeholder: formatCurrency(0.00, ''),
                            decoration: invalidAmount
                                ? BoxDecoration(
                                    color: Theme.of(context)
                                        .colors
                                        .transparent
                                        .resolveFrom(context),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context)
                                            .colors
                                            .danger
                                            .resolveFrom(context),
                                        width: 2,
                                      ),
                                    ),
                                  )
                                : BoxDecoration(
                                    color: Theme.of(context)
                                        .colors
                                        .transparent
                                        .resolveFrom(context),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context)
                                            .colors
                                            .primary
                                            .resolveFrom(context),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                            textAlign: TextAlign.center,
                            placeholderStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colors
                                  .subtleEmphasis
                                  .resolveFrom(context),
                            ),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: invalidAmount
                                  ? Theme.of(context)
                                      .colors
                                      .danger
                                      .resolveFrom(context)
                                  : Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context),
                            ),
                            maxLines: 1,
                            maxLength: 25,
                            focusNode: amountFocusNode,
                            autocorrect: false,
                            enableSuggestions: false,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: (wallet?.decimalDigits ?? 0) > 0,
                              signed: false,
                            ),
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              (wallet?.decimalDigits ?? 0) > 0
                                  ? amountFormatter
                                  : integerAmountFormatter,
                            ],
                            onChanged: (_) => handleThrottledUpdateAmount(),
                            onSubmitted: (_) {
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            prefix: Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                                child: Text(
                                  AppLocalizations.of(context)!.send,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            suffix: Center(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Text(
                                  wallet?.symbol ?? '',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (invalidAmount &&
                            (double.tryParse(walletLogic
                                        .amountController.value.text) ??
                                    0.0) >
                                0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.insufficientFunds,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colors
                                      .danger
                                      .resolveFrom(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.currentBalance(
                                  formattedBalance, wallet?.symbol ?? ''),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            CupertinoButton(
                              onPressed: handleSetMaxAmount,
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context)
                                      .withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colors
                                        .surfacePrimary
                                        .resolveFrom(context),
                                    width: 2,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .max
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colors
                                          .primary
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        if (!isLink)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              AppLocalizations.of(context)!.description,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (!isLink) const SizedBox(height: 10),
                        if (!isLink)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: CupertinoTextField(
                              controller: walletLogic.messageController,
                              placeholder:
                                  AppLocalizations.of(context)!.sendDescription,
                              minLines: 4,
                              maxLines: 10,
                              maxLength: 200,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              textAlignVertical: TextAlignVertical.top,
                              focusNode: messageFocusNode,
                              autocorrect: true,
                              enableSuggestions: true,
                            ),
                          ),
                      ],
                    ),
                    if (isSendingValid)
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
                                          : isLink
                                              ? () => handleCreateVoucher(
                                                  context, wallet?.symbol ?? '')
                                              : () => handleSend(
                                                    context,
                                                    selectedProfile?.account ??
                                                        searchedProfile
                                                            ?.account,
                                                  )
                                      : null,
                                  enabled: isSendingValid,
                                  isComplete: _isSending,
                                  completionLabel: widget.isMinting
                                      ? AppLocalizations.of(context)!
                                          .swipeToMint
                                      : isLink
                                          ? AppLocalizations.of(context)!
                                              .swipeToConfirm
                                          : AppLocalizations.of(context)!
                                              .swipeToSend,
                                  completionLabelColor: Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context),
                                  thumbColor: Theme.of(context)
                                      .colors
                                      .surfacePrimary
                                      .resolveFrom(context),
                                  width: width * 0.65,
                                  suffix: isValid
                                      ? ProfileCircle(
                                          size: 50,
                                          imageUrl:
                                              selectedProfile?.imageSmall ??
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
            ],
          ),
        ),
      ),
    );
  }
}
