import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/ratio.dart';
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

    final formattedBalance = wallet?.formattedBalance ?? '';

    return Container(
      color: ThemeColors.uiBackground.resolveFrom(context),
      child: Stack(
        children: [
          Container(
            height: progressiveClamp(130, 240, shrink),
            color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  wallet?.currencyName ?? 'Token',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.normal,
                    color: ThemeColors.text.resolveFrom(context),
                  ),
                ),
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
                              fontSize: 40,
                              fontWeight: FontWeight.normal,
                              color: ThemeColors.text.resolveFrom(context),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: ThemeColors.text.resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
          Positioned(
            width: width,
            bottom: 15,
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
                            color: ThemeColors.black,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Send',
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
      ),
    );
  }
}
