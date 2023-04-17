import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

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
    final date = transaction.date;
    final isIncoming = transaction.isIncoming(wallet.address);
    return AnimatedContainer(
      key: super.key,
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      decoration: BoxDecoration(
        color: ThemeColors.background.resolveFrom(context),
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
          Expanded(
            child: Text(
              transaction.formattedAmount(wallet, isIncoming: isIncoming),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
          Expanded(
            child: Text(
              DateFormat('dd/MM/y HH:mm').format(date.toLocal()),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
