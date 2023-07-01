import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletActions extends StatelessWidget {
  final double shrink;

  final void Function() handleSendModal;
  final void Function() handleReceive;

  const WalletActions({
    Key? key,
    this.shrink = 0,
    required this.handleSendModal,
    required this.handleReceive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);

    final blockSending = context.select(selectShouldBlockSending);

    final hasPending = context.select(selectHasProcessingTransactions);
    final newBalance = context.select(selectWalletBalance);
    final formattedBalance = formatAmount(newBalance > 0 ? newBalance : 0.0,
        decimalDigits: wallet != null ? wallet.decimalDigits : 2);

    final balance = wallet != null ? double.parse(wallet.balance) : 0.0;

    final isIncreasing = newBalance > balance;

    return Stack(
      children: [
        BlurryChild(
          child: SafeArea(
            child: SizedBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if ((1 - shrink) == 1)
                    Text(
                      wallet?.currencyName ?? 'Token',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.normal,
                        color: ThemeColors.text.resolveFrom(context),
                      ),
                    ),
                  if ((1 - shrink) == 1)
                    const SizedBox(
                      height: 5,
                    ),
                  loading && formattedBalance.isEmpty
                      ? CupertinoActivityIndicator(
                          color: ThemeColors.subtle.resolveFrom(context),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedBalance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: progressiveClamp(32, 40, shrink),
                                fontWeight: FontWeight.normal,
                                color: hasPending
                                    ? isIncreasing
                                        ? ThemeColors.primary
                                            .resolveFrom(context)
                                        : ThemeColors.secondary
                                            .resolveFrom(context)
                                    : ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                0,
                                0,
                                0,
                                3,
                              ),
                              child: Text(
                                wallet?.symbol ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: progressiveClamp(18, 22, shrink),
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          width: width,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (wallet?.locked == false)
                CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: handleSendModal,
                  borderRadius:
                      BorderRadius.circular(progressiveClamp(14, 20, shrink)),
                  color: ThemeColors.surfacePrimary.resolveFrom(context),
                  child: SizedBox(
                    height: progressiveClamp(55, 80, shrink),
                    width: progressiveClamp(55, 80, shrink),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up,
                          size: progressiveClamp(20, 40, shrink),
                          color: blockSending
                              ? ThemeColors.subtleEmphasis
                              : ThemeColors.black,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          blockSending ? 'Sending' : 'Send',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blockSending
                                ? ThemeColors.subtleEmphasis
                                : ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (wallet?.locked == false) const SizedBox(width: 40),
              CupertinoButton(
                padding: const EdgeInsets.all(5),
                onPressed: handleReceive,
                borderRadius:
                    BorderRadius.circular(progressiveClamp(14, 20, shrink)),
                color: ThemeColors.surfacePrimary.resolveFrom(context),
                child: SizedBox(
                  height: progressiveClamp(55, 80, shrink),
                  width: progressiveClamp(55, 80, shrink),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.arrow_down,
                        size: progressiveClamp(20, 40, shrink),
                        color: ThemeColors.black,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Receive',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.black,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
