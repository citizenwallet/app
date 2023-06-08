import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';

class TransactionRow extends StatelessWidget {
  final CWTransaction transaction;
  final CWWallet wallet;
  final void Function(String transactionId)? onTap;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.wallet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming(wallet.address);
    final address =
        formatHexAddress(isIncoming ? transaction.from : transaction.to);

    return GestureDetector(
      onTap: transaction.isPending || transaction.isSending
          ? null
          : () => onTap?.call(transaction.id),
      child: AnimatedContainer(
        key: super.key,
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
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
              _ => ThemeColors.uiBackground.resolveFrom(context),
            },
          ),
        ),
        child: Row(
          children: [
            transaction.state == TransactionState.sending
                ? SizedBox(
                    width: 50,
                    height: 50,
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      ),
                    ),
                  )
                : ProfileCircle(
                    size: 50,
                    imageUrl: getTransactionAuthor(
                            wallet.address, transaction.from, transaction.to)
                        .icon,
                    backgroundColor: ThemeColors.white,
                    borderColor: ThemeColors.subtle,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // '${transaction.isIncoming(wallet.address) ? transaction.from == wallet.address ? 'Me' : 'Unknown' : transaction.to == wallet.address ? 'Me' : 'Unknown'} $address',
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: ThemeColors.text.resolveFrom(context),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                    child: Text(
                      transaction.title == '' ? '...' : transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: ThemeColors.subtleText.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: Text(
                transaction.formattedAmount(wallet, isIncoming: isIncoming),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: transaction.isPending
                      ? FontWeight.normal
                      : FontWeight.w500,
                  color: isIncoming
                      ? ThemeColors.primary.resolveFrom(context)
                      : ThemeColors.text.resolveFrom(context),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}
