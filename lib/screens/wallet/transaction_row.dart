import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class TransactionRow extends StatefulWidget {
  final CWTransaction transaction;
  final CWWallet wallet;
  final Map<String, ProfileItem> profiles;
  final void Function(String transactionId)? onTap;
  final void Function(String address)? onLoadProfile;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.wallet,
    required this.profiles,
    this.onTap,
    this.onLoadProfile,
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

    if (widget.onLoadProfile != null) widget.onLoadProfile!(address);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final wallet = widget.wallet;
    final onTap = widget.onTap;

    final isIncoming = transaction.isIncoming(wallet.account);
    final address = isIncoming ? transaction.from : transaction.to;
    final formattedAddress = formatHexAddress(address);

    final profile = widget.profiles[address];

    return GestureDetector(
      onTap:
          transaction.isProcessing ? null : () => onTap?.call(transaction.id),
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
                      _ => profile != null && profile.loading
                          ? const PulsingContainer(
                              height: 50,
                              width: 50,
                              borderRadius: 25,
                            )
                          : ProfileCircle(
                              size: 50,
                              imageUrl: profile != null
                                  ? profile.profile.imageMedium
                                  : getTransactionAuthor(
                                      wallet.account,
                                      transaction.from,
                                      transaction.to,
                                    ).icon,
                              backgroundColor: ThemeColors.white,
                            ),
                    },
                    if (transaction.title != '')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: ThemeColors.background.resolveFrom(context),
                          ),
                          child: Icon(
                            CupertinoIcons.text_alignleft,
                            size: 14,
                            color: ThemeColors.subtleText.resolveFrom(context),
                          ),
                        ),
                      ),
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
                              width: 100,
                            )
                          : Text(
                              profile != null
                                  ? profile.profile.name
                                  : 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.normal,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                      if (profile != null && profile.loading)
                        const SizedBox(height: 2),
                      profile != null && profile.loading
                          ? const PulsingContainer(
                              height: 20,
                              width: 80,
                            )
                          : SizedBox(
                              height: 20,
                              child: Text(
                                profile != null
                                    ? '@${profile.profile.username}'
                                    : formattedAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
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
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ThemeColors.white,
                ),
                child: (transaction.state == TransactionState.success)
                    ? const Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: 1,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.checkmark_alt,
                                color: ThemeColors.black,
                                size: 14,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 5,
                            child: Center(
                              child: Icon(
                                CupertinoIcons.checkmark_alt,
                                color: ThemeColors.black,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Icon(
                          switch (transaction.state) {
                            TransactionState.sending => isIncoming
                                ? CupertinoIcons.arrow_down
                                : CupertinoIcons.arrow_up,
                            TransactionState.pending =>
                              CupertinoIcons.checkmark_alt,
                            TransactionState.fail =>
                              CupertinoIcons.exclamationmark,
                            _ => CupertinoIcons.checkmark_alt,
                          },
                          color: ThemeColors.black,
                          size: 14,
                        ),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
