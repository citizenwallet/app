import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class WalletActionsMore extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;
  final bool refreshing;
  final bool isOpened;

  final void Function()? handleSendModal;
  final void Function()? handleReceive;
  final void Function(PluginConfig pluginConfig)? handlePlugin;
  final void Function()? handleCards;
  final void Function()? handleMint;
  final void Function()? handleVouchers;

  WalletActionsMore({
    super.key,
    this.shrink = 0,
    this.refreshing = false,
    this.handleSendModal,
    this.handleReceive,
    this.handlePlugin,
    this.handleCards,
    this.handleMint,
    this.handleVouchers,
    this.isOpened = false
  });

  bool _showAdditionalButtons = false;
  void handleOpenAbout() {
    _showAdditionalButtons = !_showAdditionalButtons;
  }

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

    final showVouchers = !kIsWeb &&
        wallet?.locked == false &&
        (!loading || !firstLoad) &&
        wallet?.doubleBalance != 0.0 &&
        handleSendModal != null;

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

    void handleClick(String value) {
      switch (value) {
        case 'Logout':
          break;
        case 'Settings':
          break;
      }
    }
    return Stack(
      children: [
        SafeArea(
          top: false,
          bottom: false,
          child: AnimatedContainer(
            width: 1000,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            height: isOpened ? 50 : 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ThemeColors.uiBackgroundAlt,
                  ThemeColors.uiBackgroundAlt,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(0.0)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context), 
                              width:
                                  2, 
                            ),
                          ),
                          child: SizedBox(
                            height: 20,
                            width: 20, 
                            child: Icon(
                              CupertinoIcons.plus,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              size: 16, 
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "Top up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context), 
                              width:
                                  2, 
                            ),
                          ),
                          child: SizedBox(
                            height: 20, 
                            width: 20, 
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "Custom Action",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context), 
                              width:
                                  2, 
                            ),
                          ),
                          child:  SizedBox(
                            height: 20, 
                            width: 20, 
                            child: Icon(
                              CupertinoIcons.person_2,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context), 
                              size: 16, 
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "View Community Dashboard",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
