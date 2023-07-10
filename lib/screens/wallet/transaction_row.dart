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
  final bool loading;

  const TransactionRow({
    super.key,
    required this.transaction,
    required this.wallet,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isIncoming = transaction.isIncoming(wallet.account);
    final address =
        formatHexAddress(isIncoming ? transaction.from : transaction.to);

    return GestureDetector(
      onTap:
          transaction.isProcessing ? null : () => onTap?.call(transaction.id),
      child: AnimatedContainer(
        key: super.key,
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
              _ => ThemeColors.uiBackground.resolveFrom(context),
            },
          ),
        ),
        child: Stack(
          children: [
            Row(
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
                  _ => loading
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
                          imageUrl: getTransactionAuthor(wallet.account,
                                  transaction.from, transaction.to)
                              .icon,
                          backgroundColor: ThemeColors.white,
                          borderColor: ThemeColors.subtle,
                        ),
                },
                const SizedBox(width: 10),
                if (loading)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0x...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: ThemeColors.text.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!loading)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: ThemeColors.text.resolveFrom(context),
                          ),
                        ),
                        if (transaction.title != '' && !transaction.isFailed)
                          SizedBox(
                            height: 20,
                            child: Text(
                              transaction.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color:
                                    ThemeColors.subtleText.resolveFrom(context),
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
                if (loading)
                  SizedBox(
                    width: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '',
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
                if (!loading)
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
            if (!loading)
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
