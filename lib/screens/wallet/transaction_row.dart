import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  final Wallet wallet;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.wallet,
  });

  @override
  Widget build(BuildContext context) {
    final date = transaction.date;
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
      decoration: BoxDecoration(
        color: ThemeColors.background.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ThemeColors.subtle.resolveFrom(context),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              transaction.formattedAmount(wallet),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
