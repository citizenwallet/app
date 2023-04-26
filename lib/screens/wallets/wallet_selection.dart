import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/state/wallets/logic.dart';
import 'package:citizenwallet/state/wallets/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/text_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WalletSelection extends StatefulWidget {
  final WalletsLogic walletLogic;

  const WalletSelection({
    Key? key,
    required this.walletLogic,
  }) : super(key: key);

  @override
  WalletSelectionState createState() => WalletSelectionState();
}

class WalletSelectionState extends State<WalletSelection> {
  late WalletsLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    _walletLogic = widget.walletLogic;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _walletLogic.getWallets();
    });
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleSubmit(BuildContext context, CWWallet wallet) {
    GoRouter.of(context).pop(wallet);
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select((WalletsState state) => state.loadingWallets);
    final wallets = context.watch<WalletsState>().wallets;

    final badgeColor = ThemeColors.surfaceBackground.resolveFrom(context);
    final badgeTextColor = ThemeColors.surfaceText.resolveFrom(context);

    return DismissibleModalPopup(
      modalKey: 'wallet-selection',
      maxHeight: 120,
      paddingSides: 0,
      topRadius: 0,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      onDismissed: (_) {
        handleDismiss(context);
      },
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: loading
                  ? Center(
                      child: CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      ),
                    )
                  : CustomScrollView(
                      scrollDirection: Axis.horizontal,
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            childCount: wallets.length,
                            (context, index) {
                              final wallet = wallets[index];

                              return GestureDetector(
                                onTap: () {
                                  handleSubmit(context, wallet);
                                },
                                child: SizedBox(
                                  height: 100,
                                  width: 100,
                                  child: Column(
                                    children: [
                                      TextBadge(
                                        text: wallet.symbol,
                                        size: 40,
                                        color: badgeColor,
                                        textColor: badgeTextColor,
                                      ),
                                      Text(
                                        wallet.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 60,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}