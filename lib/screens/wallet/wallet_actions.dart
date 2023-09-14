import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletActions extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;

  final void Function()? handleSendModal;
  final void Function()? handleReceive;
  final void Function()? handleVouchers;

  WalletActions({
    Key? key,
    this.shrink = 0,
    this.handleSendModal,
    this.handleReceive,
    this.handleVouchers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final loading = context.select((WalletState state) => state.loading);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final wallet = context.select((WalletState state) => state.wallet);

    final blockSending = context.select(selectShouldBlockSending);
    final sendLoading = context.read<WalletState>().transactionSendLoading;

    final hasPending = context.select(selectHasProcessingTransactions);
    final newBalance = context.select(selectWalletBalance);

    final formattedBalance = formatAmount(
      double.parse(fromDoubleUnit(
        '${newBalance > 0 ? newBalance : 0.0}',
        decimals: wallet?.decimalDigits ?? 2,
      )),
      decimalDigits: 2,
    );

    final balance = wallet != null ? double.parse(wallet.balance) : 0.0;

    final isIncreasing = newBalance > balance;

    final coinSize = progressiveClamp(2, 80, shrink);
    final coinNameSize = progressiveClamp(10, 22, shrink);

    final buttonOffset =
        (1 - shrink) < 0.6 ? 90.0 : progressiveClamp(90, 110, shrink);

    final buttonSize =
        (1 - shrink) < 0.6 ? 60.0 : progressiveClamp(50, 80, shrink);
    final buttonIconSize =
        (1 - shrink) < 0.6 ? 30.0 : progressiveClamp(18, 40, shrink);
    final buttonFontSize =
        (1 - shrink) < 0.6 ? 12.0 : progressiveClamp(10, 14, shrink);

    return Stack(
      children: [
        BlurryChild(
          child: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: ThemeColors.subtle.resolveFrom(context),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if ((1 - shrink) > 0.6 && wallet != null)
                    CoinLogo(
                      size: coinSize,
                      logo: wallet.currencyLogo,
                    ),
                  if ((1 - shrink) > 0.75)
                    const SizedBox(
                      height: 10,
                    ),
                  if ((1 - shrink) > 0.75)
                    Text(
                      wallet?.currencyName ?? 'Token',
                      style: TextStyle(
                        fontSize: coinNameSize,
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
                            if ((1 - shrink) < 0.6 && wallet != null) ...[
                              CoinLogo(
                                size: 40,
                                logo: wallet.currencyLogo,
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              formattedBalance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.start,
                              style: TextStyle(
                                fontSize: (1 - shrink) < 0.6
                                    ? 32
                                    : progressiveClamp(12, 40, shrink),
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
                                  fontSize: (1 - shrink) < 0.6
                                      ? 22
                                      : progressiveClamp(8, 22, shrink),
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
              Expanded(
                child: SizedBox(
                  height: buttonSize + 10,
                  child: ListView(
                    controller: controller,
                    physics:
                        const ScrollPhysics(parent: BouncingScrollPhysics()),
                    scrollDirection: Axis.horizontal,
                    children: [
                      SizedBox(
                        width: (width / 2) - buttonOffset,
                      ),
                      if (wallet?.locked == false &&
                          (!loading || !firstLoad) &&
                          handleSendModal != null)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: blockSending ? () => () : handleSendModal,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color:
                              ThemeColors.surfacePrimary.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_up,
                                  size: buttonIconSize,
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
                                    fontSize: buttonFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (wallet?.locked == false) const SizedBox(width: 40),
                      if ((!loading || !firstLoad) && handleReceive != null)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: sendLoading ? () => () : handleReceive,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color:
                              ThemeColors.surfacePrimary.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_down,
                                  size: buttonIconSize,
                                  color: sendLoading
                                      ? ThemeColors.subtleEmphasis
                                      : ThemeColors.black,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Receive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sendLoading
                                        ? ThemeColors.subtleEmphasis
                                        : ThemeColors.black,
                                    fontSize: buttonFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (wallet?.locked == false) const SizedBox(width: 40),
                      if (wallet?.locked == false &&
                          (!loading || !firstLoad) &&
                          handleSendModal != null)
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: sendLoading ? () => () : handleVouchers,
                          borderRadius: BorderRadius.circular(
                              progressiveClamp(14, 20, shrink)),
                          color: ThemeColors.background.resolveFrom(context),
                          child: SizedBox(
                            height: buttonSize,
                            width: buttonSize,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.ticket,
                                  size: buttonIconSize,
                                  color: sendLoading
                                      ? ThemeColors.subtleEmphasis
                                      : ThemeColors.text.resolveFrom(context),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Vouchers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: sendLoading
                                        ? ThemeColors.subtleEmphasis
                                        : ThemeColors.text.resolveFrom(context),
                                    fontSize: buttonFontSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          width: width,
          bottom: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: buttonSize + 10,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: <Color>[
                      ThemeColors.uiBackgroundAltTransparent50
                          .resolveFrom(context),
                      ThemeColors.uiBackgroundAltTransparent
                          .resolveFrom(context),
                    ], // Gradient from https://learnui.design/tools/gradient-generator.html
                    tileMode: TileMode.mirror,
                  ),
                ),
              ),
              Container(
                height: buttonSize + 10,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: <Color>[
                      ThemeColors.uiBackgroundAltTransparent50
                          .resolveFrom(context),
                      ThemeColors.uiBackgroundAltTransparent
                          .resolveFrom(context),
                    ], // Gradient from https://learnui.design/tools/gradient-generator.html
                    tileMode: TileMode.mirror,
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
