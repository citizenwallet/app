import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class SelectAccountModal extends StatefulWidget {
  final String title;
  final List<CWWallet> wallets;

  const SelectAccountModal({
    super.key,
    this.title = 'Select Account',
    required this.wallets,
  });

  @override
  SelectAccountModalState createState() => SelectAccountModalState();
}

class SelectAccountModalState extends State<SelectAccountModal> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initial requests go here

      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));
  }

  void handleWalletTap(String address, String alias) async {
    final navigator = GoRouter.of(context);

    HapticFeedback.heavyImpact();

    navigator.pop((address, alias));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final cwWallets = widget.wallets;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(
            left: 10,
            right: 10,
            top: 20,
          ),
          bottom: false,
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: title,
              ),
              Expanded(
                child: CustomScrollView(
                  controller: ModalScrollController.of(context),
                  scrollBehavior: const CupertinoScrollBehavior(),
                  slivers: [
                    if (cwWallets.isEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          childCount: 1,
                          (context, index) {
                            return CupertinoActivityIndicator(
                              color: Theme.of(context)
                                  .colors
                                  .subtle
                                  .resolveFrom(context),
                            );
                          },
                        ),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: cwWallets.isEmpty ? 0 : cwWallets.length,
                        (context, index) {
                          final wallet = cwWallets[index];

                          return WalletRow(
                            key: Key('${wallet.account}_${wallet.alias}'),
                            wallet,
                            communities: const {},
                            profiles: const {},
                            onTap: () => handleWalletTap(
                              wallet.account,
                              wallet.alias,
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(
                        height: 120,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
