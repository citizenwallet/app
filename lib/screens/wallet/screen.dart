import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallet/wallet_selection.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/mock_data.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/text_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Wallet name';

  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  late WalletLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _walletLogic = WalletLogic(context);

      _walletLogic.getWallet(mockWalletId);
    });
  }

  void handleWalletSelection(BuildContext context) async {
    final wallet = await showCupertinoModalPopup<Wallet?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => WalletSelection(walletLogic: _walletLogic),
    );

    if (wallet != null) {
      _walletLogic.getWallet(wallet.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.select((WalletState state) => state.loading);
    final wallet = context.select((WalletState state) => state.wallet);
    var balance = '0.00';
    if (wallet != null) {
      balance = NumberFormat.currency(
              name: wallet.name, symbol: wallet.symbol, decimalDigits: 2)
          .format(wallet.balance);
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: widget.title,
            actionButton: CupertinoButton(
              onPressed: () => handleWalletSelection(context),
              child: !loading && wallet != null
                  ? TextBadge(
                      text: wallet.symbol,
                      size: 20,
                      color: ThemeColors.surfaceBackground.resolveFrom(context),
                      textColor: ThemeColors.surfaceText.resolveFrom(context),
                    )
                  : const SizedBox(),
            ),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: loading
                      ? CupertinoActivityIndicator(
                          color: ThemeColors.subtle.resolveFrom(context),
                        )
                      : Text(
                          balance,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
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
