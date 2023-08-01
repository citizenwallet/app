import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/screens/profile/screen.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_badge.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class TransactionScreen extends StatefulWidget {
  final String? transactionId;
  final WalletLogic logic;
  final ProfilesLogic profilesLogic;

  const TransactionScreen({
    Key? key,
    required this.transactionId,
    required this.logic,
    required this.profilesLogic,
  }) : super(key: key);

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

    final sent = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (_) => SendModal(
        logic: widget.logic,
        profilesLogic: widget.profilesLogic,
        to: address,
      ),
    );

    if (sent == true) {
      navigator.pop();
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

    final sent = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (_) => SendModal(
        logic: widget.logic,
        profilesLogic: widget.profilesLogic,
        to: address,
      ),
    );

    if (sent == true) {
      navigator.pop();
    }
  }

  void handleViewProfile(String account) {
    showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      useRootNavigator: true,
      builder: (_) => ProfileScreen(
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

    final isIncoming = transaction.isIncoming(wallet.account);

    final from = transaction.isIncoming(wallet.account)
        ? transaction.from
        : transaction.to;

    final author =
        getTransactionAuthor(wallet.account, transaction.from, transaction.to);

    final profile =
        context.select((ProfilesState state) => state.profiles[from]);

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
                                  ProfileBadge(
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
                                'Transaction details',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction ID',
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
                                    child: GestureDetector(
                                      onTap: () => handleCopy(transaction.id),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            5, 0, 5, 0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                formatHexAddress(
                                                    transaction.id),
                                                textAlign: TextAlign.end,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.normal,
                                                  color: ThemeColors.text
                                                      .resolveFrom(context),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Icon(
                                              CupertinoIcons.square_on_square,
                                              size: 12,
                                              color: ThemeColors.touchable
                                                  .resolveFrom(context),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                    'When',
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
                                    DateFormat.yMd()
                                        .add_Hm()
                                        .format(transaction.date),
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What',
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
                                    child: Text(
                                      transaction.title != ''
                                          ? transaction.title
                                          : '...',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                        if (!wallet.locked &&
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
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: ThemeColors.black,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.reply,
                                        color: ThemeColors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!wallet.locked &&
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
                                            transaction.title,
                                          ),
                                  borderRadius: BorderRadius.circular(25),
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Send again',
                                        style: TextStyle(
                                          color: ThemeColors.black,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
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
