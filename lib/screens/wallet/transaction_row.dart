import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
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
    return GestureDetector(
      onTap: () => onTap?.call(transaction.id),
      child: AnimatedContainer(
        key: super.key,
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        height: 80,
        decoration: BoxDecoration(
          color: transaction.isPending
              ? ThemeColors.subtleEmphasis.resolveFrom(context)
              : ThemeColors.subtle.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            width: 2,
            color: transaction.isPending
                ? ThemeColors.secondary.resolveFrom(context)
                : ThemeColors.uiBackground.resolveFrom(context),
          ),
        ),
        child: Row(
          children: [
            const ProfileCircle(
              size: 50,
              imageUrl: 'assets/icons/coin.svg',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // transaction.from,
                    transaction.to == wallet.address ? 'Me' : 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: ThemeColors.text.resolveFrom(context),
                    ),
                  ),
                  Text(
                    transaction.title == '' ? '...' : transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: ThemeColors.subtleText.resolveFrom(context),
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