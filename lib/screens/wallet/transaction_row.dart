import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:citizenwallet/widgets/wallet/transaction_state_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class TransactionRow extends StatefulWidget {
  final CWTransaction transaction;
  final String? logo;
  final CWWallet wallet;
  final Map<String, ProfileItem> profiles;
  final Map<String, Voucher> vouchers;
  final void Function(String transactionId)? onTap;
  final void Function()? onProcessingTap;
  final void Function(String address)? onLoad;

  const TransactionRow({
    super.key,
    required this.transaction,
    this.logo,
    required this.wallet,
    required this.profiles,
    required this.vouchers,
    this.onTap,
    this.onProcessingTap,
    this.onLoad,
  });

  @override
  TransactionRowState createState() => TransactionRowState();
}

class TransactionRowState extends State<TransactionRow> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() {
    final transaction = widget.transaction;
    final wallet = widget.wallet;
    final isIncoming = transaction.isIncoming(wallet.account);
    final address = isIncoming ? transaction.from : transaction.to;

    if (widget.onLoad != null) widget.onLoad!(address);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final wallet = widget.wallet;
    final onTap = widget.onTap;
    final onProcessingTap = widget.onProcessingTap;

    final isIncoming = transaction.isIncoming(wallet.account);
    final address = isIncoming ? transaction.from : transaction.to;
    final addressEmpty = isEmptyAddress(address);
    final formattedAddress = addressEmpty ? '' : formatHexAddress(address);

    final profile = widget.profiles[address];
    final voucher = widget.vouchers[address];

    return GestureDetector(
      onTap: transaction.isProcessing
          ? isIncoming
              ? null
              : () => onProcessingTap?.call()
          : () => onTap?.call(transaction.id),
      child: AnimatedContainer(
        key: widget.key,
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        height: 90,
        decoration: BoxDecoration(
          color: transaction.isPending || transaction.isSending
              ? ThemeColors.subtleEmphasis.resolveFrom(context)
              : ThemeColors.subtle.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: switch (transaction.state) {
              TransactionState.sending =>
                ThemeColors.secondary.resolveFrom(context),
              TransactionState.pending =>
                ThemeColors.primary.resolveFrom(context),
              _ => ThemeColors.uiBackgroundAlt.resolveFrom(context),
            },
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    switch (transaction.state) {
                      TransactionState.sending => SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: CupertinoActivityIndicator(
                              color: ThemeColors.subtle.resolveFrom(context),
                            ),
                          ),
                        ),
                      _ => voucher != null || addressEmpty
                          ? CoinLogo(
                              size: 50,
                              logo: widget.logo,
                            )
                          : ProfileCircle(
                              size: 50,
                              imageUrl: profile?.profile.imageMedium,
                            )
                    },
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profile != null && profile.loading
                          ? const PulsingContainer(
                              height: 24,
                              width: 100,
                            )
                          : RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: voucher != null
                                        ? isIncoming
                                            ? 'Voucher redeemed'
                                            : 'Voucher created'
                                        : profile != null
                                            ? profile.profile.name
                                            : addressEmpty
                                                ? wallet.currencyName
                                                : 'Anonymous',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                    ),
                                  ),
                                  if (voucher == null)
                                    TextSpan(
                                      text: profile != null
                                          ? ' @${profile.profile.username}'
                                          : ' $formattedAddress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: ThemeColors.subtleText
                                            .resolveFrom(context),
                                      ),
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 20,
                        child: Text(
                          transaction.description.isNotEmpty
                              ? transaction.description
                              : addressEmpty
                                  ? 'Minted'
                                  : 'no description',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: ThemeColors.subtleText.resolveFrom(context),
                          ),
                        ),
                      ),
                      if (voucher != null && profile != null && profile.loading)
                        const SizedBox(height: 2),
                      voucher != null && profile != null && profile.loading
                          ? const PulsingContainer(
                              height: 16,
                              width: 80,
                            )
                          : SizedBox(
                              height: 16,
                              child: Text(
                                DateFormat.yMMMd()
                                    .add_Hm()
                                    .format(transaction.date.toLocal()),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: ThemeColors.subtleText
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                      if (transaction.isFailed && transaction.error != '')
                        SizedBox(
                          height: 20,
                          child: Text(
                            transaction.error,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: ThemeColors.danger.resolveFrom(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
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
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: isIncoming
                              ? ThemeColors.primary.resolveFrom(context)
                              : ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        wallet.symbol,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isIncoming
                              ? ThemeColors.primary.resolveFrom(context)
                              : ThemeColors.text.resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: TransactionStateIcon(
                state: transaction.state,
                isIncoming: isIncoming,
              ),
            )
          ],
        ),
      ),
    );
  }
}
