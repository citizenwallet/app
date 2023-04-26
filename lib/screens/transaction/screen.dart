import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/screens/wallet/send_modal.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionScreen extends StatefulWidget {
  final String? address;
  final String? transactionId;

  const TransactionScreen({
    Key? key,
    required this.address,
    required this.transactionId,
  }) : super(key: key);

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  late WalletLogic logic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      logic = WalletLogic(context);

      if (widget.address != null) {
        logic.instantiateWalletFromDB(widget.address!);
      }
    });
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleReply(String address) async {
    logic.prepareReplyTransaction(address);

    HapticFeedback.lightImpact();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => SendModal(
        logic: logic,
      ),
    );
  }

  void handleReplay(
    String address,
    double amount,
    String message,
  ) async {
    logic.prepareReplayTransaction(address, amount: amount, message: message);

    HapticFeedback.lightImpact();

    await showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (_) => SendModal(
        logic: logic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);
    final CWTransaction? transaction = context.select((WalletState state) =>
        state.transactions
            .firstWhere((element) => element.id == widget.transactionId));

    final loading = context.select((WalletState state) => state.loading);

    if (wallet == null || transaction == null || widget.address == null) {
      return const SizedBox();
    }

    if (loading) {
      return CupertinoActivityIndicator(
        color: ThemeColors.subtle.resolveFrom(context),
      );
    }

    final isIncoming = transaction.isIncoming(wallet.address);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ListView(
                          children: [
                            const SizedBox(height: 60),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                ProfileCircle(
                                  size: 80,
                                  imageUrl: 'assets/icons/coin.svg',
                                  backgroundColor: ThemeColors.transparent,
                                  borderColor: ThemeColors.transparent,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              transaction.formattedAmount(wallet,
                                  isIncoming: isIncoming),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: transaction.isPending
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                color: isIncoming
                                    ? ThemeColors.primary.resolveFrom(context)
                                    : ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              transaction.isIncoming(wallet.address)
                                  ? transaction.from == wallet.address
                                      ? 'Me'
                                      : 'Unknown'
                                  : transaction.to == wallet.address
                                      ? 'Me'
                                      : 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  child: SelectableText(
                                    transaction.id,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: () => handleDismiss(context),
                          child: const Icon(
                            CupertinoIcons.back,
                          ),
                        ),
                      ),
                      if (!wallet.locked && !loading)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              transaction.isIncoming(wallet.address)
                                  ? CupertinoButton(
                                      padding: const EdgeInsets.all(5),
                                      onPressed: () =>
                                          handleReply(transaction.from),
                                      borderRadius: BorderRadius.circular(25),
                                      color: ThemeColors.primary
                                          .resolveFrom(context),
                                      child: Icon(
                                        CupertinoIcons.reply,
                                        color: ThemeColors.white
                                            .resolveFrom(context),
                                      ),
                                    )
                                  : CupertinoButton(
                                      padding: const EdgeInsets.all(5),
                                      onPressed: () => handleReplay(
                                        transaction.to,
                                        transaction.amount,
                                        transaction.title,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      color: ThemeColors.primary
                                          .resolveFrom(context),
                                      child: Icon(
                                        CupertinoIcons.refresh_thick,
                                        color: ThemeColors.white
                                            .resolveFrom(context),
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
    );
  }
}
