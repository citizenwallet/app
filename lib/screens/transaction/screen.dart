import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/modals/profile/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_badge.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

class TransactionScreenState extends State<TransactionScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
    });
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleReply(String address) async {
    widget.logic.prepareReplyTransaction(address);

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final sent = await navigator
        .push<bool?>('/wallet/${widget.logic.account}/send', extra: {
      'walletLogic': widget.logic,
      'profilesLogic': widget.profilesLogic,
      'to': address,
    });

    if (sent == true) {
      navigator.pop(sent);
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

    final sent = await navigator
        .push<bool?>('/wallet/${widget.logic.account}/send', extra: {
      'walletLogic': widget.logic,
      'profilesLogic': widget.profilesLogic,
      'to': address,
      'amount': (double.tryParse(amount) ?? 0.0).toStringAsFixed(2),
      'message': message,
    });

    if (sent == true) {
      navigator.pop(sent);
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
    final CWTransaction? transaction = context.select((WalletState state) =>
        state.transactions
            .firstWhereOrNull((element) => element.id == widget.transactionId));

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

    final author =
        getTransactionAuthor(wallet.account, transaction.from, transaction.to);

    final profile =
        context.select((ProfilesState state) => state.profiles[from]);

    final vouchers = context.select(selectMappedVoucher);

    final voucher = vouchers[from];

    final hasDescription = transaction.description != '';

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
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
                                          ? ThemeColors.primary
                                              .resolveFrom(context)
                                          : ThemeColors.text
                                              .resolveFrom(context),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    wallet.symbol,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isIncoming
                                          ? ThemeColors.primary
                                              .resolveFrom(context)
                                          : ThemeColors.text
                                              .resolveFrom(context),
                                    ),
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
                                  color: ThemeColors.text.resolveFrom(context),
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
                                      color:
                                          ThemeColors.text.resolveFrom(context),
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
                                          color: ThemeColors.subtleEmphasis
                                              .resolveFrom(context),
                                          textColor: ThemeColors.touchable
                                              .resolveFrom(context),
                                          suffix: Icon(
                                            CupertinoIcons.square_on_square,
                                            size: 14,
                                            color: ThemeColors.touchable
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
                                      color:
                                          ThemeColors.text.resolveFrom(context),
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
                                      color:
                                          ThemeColors.text.resolveFrom(context),
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
                                        color: ThemeColors.text
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
                                          color: ThemeColors.background
                                              .resolveFrom(context),
                                          border: Border.all(
                                            color: ThemeColors.border
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
                                            color: ThemeColors.text
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
                              color: ThemeColors.primary.resolveFrom(context),
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
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.reply,
                                        style: const TextStyle(
                                          color: ThemeColors.black,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      const Icon(
                                        CupertinoIcons.reply,
                                        color: ThemeColors.black,
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
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.sendAgain,
                                        style: const TextStyle(
                                          color: ThemeColors.black,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      const Icon(
                                        CupertinoIcons.refresh_thick,
                                        color: ThemeColors.black,
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
