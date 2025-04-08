import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/transaction.dart' as transaction_state;
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TransactionScreen extends StatefulWidget {
  final String? transactionId;
  final WalletLogic logic;
  final ProfilesLogic profilesLogic;

  const TransactionScreen({
    super.key,
    required this.transactionId,
    required this.logic,
    required this.profilesLogic,
  });

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen>
    with WidgetsBindingObserver {
  late transaction_state.TransactionState _transactionState;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transactionState = context.read<transaction_state.TransactionState>();

      onLoad();
    });
  }

  void onLoad() {
    _transactionState.fetchTransaction();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        onLoad();
        break;
      default:
    }
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleReply(String address) async {
    widget.logic.prepareReplyTransaction(address);

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final walletLogic = widget.logic;
    final profilesLogic = widget.profilesLogic;

    walletLogic.addressController.text = address;

    final profile = await profilesLogic.getProfile(address);

    walletLogic.updateAddress(override: profile != null);

    final sent = await navigator
        .push<bool?>('/wallet/${widget.logic.account}/send/$address', extra: {
      'walletLogic': widget.logic,
      'profilesLogic': widget.profilesLogic,
    });

    walletLogic.clearInputControllers();
    profilesLogic.clearSearch(notify: false);

    if (sent == true) {
      if (navigator.canPop()) {
        navigator.pop(sent);
      } else {
        navigator.go('/wallet/${widget.logic.account}');
      }
    }
  }

  void handleCopy(String transactionId) {
    Clipboard.setData(ClipboardData(text: transactionId));

    HapticFeedback.lightImpact();
  }

  void handleReplay(
    String address,
    String amount,
    String message,
  ) async {
    widget.logic
        .prepareReplayTransaction(address, amount: amount, message: message);

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final walletLogic = widget.logic;
    final profilesLogic = widget.profilesLogic;

    final parsedAmount = (double.tryParse(amount) ?? 0.0).toStringAsFixed(2);

    walletLogic.addressController.text = address;
    walletLogic.amountController.text = parsedAmount;
    walletLogic.messageController.text = message;
    walletLogic.updateMessage();
    walletLogic.updateListenerAmount();

    final profile = await profilesLogic.getProfile(address);

    walletLogic.updateAddress(override: profile != null);
    walletLogic.updateAmount();

    final sent = await navigator
        .push<bool?>('/wallet/${widget.logic.account}/send/$address', extra: {
      'walletLogic': walletLogic,
      'profilesLogic': profilesLogic,
    });

    walletLogic.clearInputControllers();
    profilesLogic.clearSearch(notify: false);

    if (sent == true) {
      if (navigator.canPop()) {
        navigator.pop(sent);
      } else {
        navigator.go('/wallet/${widget.logic.account}');
      }
    }
  }

  void handleViewProfile(String account) {
    showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (_) => ProfileModal(
        account: account,
        readonly: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    final wallet = context.select((WalletState state) => state.wallet);

    final transaction =
        context.watch<transaction_state.TransactionState>().transaction;

    final loading = context.select((WalletState state) => state.loading);

    final blockSending = context.select(selectShouldBlockSending);

    if (wallet == null || transaction == null) {
      return const SizedBox();
    }

    final config = context.select((WalletState state) => state.config);

    final isIncoming = transaction.isIncoming(wallet.account);

    final from = transaction.isIncoming(wallet.account)
        ? transaction.from
        : transaction.to;

    final profile =
        context.select((ProfilesState state) => state.profiles[from]);

    final vouchers = context.select(selectMappedVoucher);

    final voucher = vouchers[from];

    final hasDescription = transaction.description != '';

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: Theme.of(context).colors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(left: 10, right: 10),
            child: Flex(
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: ListView(
                            children: [
                              SizedBox(height: safePadding),
                              const SizedBox(height: 40),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  voucher != null
                                      ? CoinLogo(
                                          size: 160,
                                          logo: config?.community.logo,
                                        )
                                      : ProfileBadge(
                                          size: 160,
                                          fontSize: 14,
                                          profile: profile?.profile,
                                          loading: profile?.loading ?? false,
                                          onTap: () => handleViewProfile(from),
                                        ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    isIncoming
                                        ? '+ ${transaction.formattedAmount}'
                                        : '- ${transaction.formattedAmount}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.normal,
                                      color: isIncoming
                                          ? Theme.of(context)
                                              .colors
                                              .primary
                                              .resolveFrom(context)
                                          : Theme.of(context)
                                              .colors
                                              .text
                                              .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  CoinLogo(
                                    size: 32,
                                    logo: wallet.currencyLogo,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              Text(
                                AppLocalizations.of(context)!.transactionDetais,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colors
                                      .text
                                      .resolveFrom(context),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.transactionID,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .colors
                                          .text
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Chip(
                                          formatHexAddress(transaction.hash),
                                          onTap: () =>
                                              handleCopy(transaction.hash),
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .colors
                                              .subtleEmphasis
                                              .resolveFrom(context),
                                          textColor: Theme.of(context)
                                              .colors
                                              .touchable
                                              .resolveFrom(context),
                                          suffix: Icon(
                                            CupertinoIcons.square_on_square,
                                            size: 14,
                                            color: Theme.of(context)
                                                .colors
                                                .touchable
                                                .resolveFrom(context),
                                          ),
                                          maxWidth: 140,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.date,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .colors
                                          .text
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  Text(
                                    DateFormat.yMMMd()
                                        .add_Hm()
                                        .format(transaction.date.toLocal()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color: Theme.of(context)
                                          .colors
                                          .text
                                          .resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (hasDescription)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(context)
                                            .colors
                                            .text
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              if (hasDescription) const SizedBox(height: 10),
                              if (hasDescription)
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colors
                                              .background
                                              .resolveFrom(context),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colors
                                                .border
                                                .resolveFrom(context),
                                          ),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 10, 10, 10),
                                        child: Text(
                                          transaction.description != ''
                                              ? transaction.description
                                              : '...',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            color: Theme.of(context)
                                                .colors
                                                .text
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              if (hasDescription) const SizedBox(height: 200),
                            ],
                          ),
                        ),
                        Positioned(
                          top: safePadding,
                          left: 0,
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(5),
                            onPressed: () => handleDismiss(context),
                            child: Icon(
                              CupertinoIcons.back,
                              color: Theme.of(context)
                                  .colors
                                  .primary
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                        if (voucher == null &&
                            !wallet.locked &&
                            !loading &&
                            transaction.isIncoming(wallet.account))
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  onPressed: blockSending
                                      ? null
                                      : () => handleReply(transaction.from),
                                  borderRadius: BorderRadius.circular(25),
                                  color: Theme.of(context)
                                      .colors
                                      .surfacePrimary
                                      .resolveFrom(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.reply,
                                        style: TextStyle(
                                          color: Theme.of(context).colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.reply,
                                        color: Theme.of(context).colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (voucher == null &&
                            !wallet.locked &&
                            !loading &&
                            !transaction.isIncoming(wallet.account))
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CupertinoButton(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                  onPressed: blockSending
                                      ? null
                                      : () => handleReplay(
                                            transaction.to,
                                            transaction.amount,
                                            transaction.description,
                                          ),
                                  borderRadius: BorderRadius.circular(25),
                                  color: Theme.of(context)
                                      .colors
                                      .surfacePrimary
                                      .resolveFrom(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.sendAgain,
                                        style: TextStyle(
                                          color: Theme.of(context).colors.black,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.refresh_thick,
                                        color: Theme.of(context).colors.black,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
