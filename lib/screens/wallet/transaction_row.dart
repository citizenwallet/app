import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';

class TransactionRow extends StatelessWidget {
  final CWTransaction transaction;
  final CWWallet wallet;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming(wallet.address);
    return AnimatedContainer(
      key: super.key,
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      height: 80,
      decoration: BoxDecoration(
        color: transaction.isPending
            ? ThemeColors.border.resolveFrom(context)
            : ThemeColors.background.resolveFrom(context),
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
            size: 60,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: CupertinoColors.black,
                  ),
                ),
                // const SizedBox(height: 5),
                Text(
                  transaction.title == '' ? '...' : transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: CupertinoColors.systemGrey,
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
                fontWeight:
                    transaction.isPending ? FontWeight.normal : FontWeight.w500,
                color: isIncoming
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
