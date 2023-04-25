import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SwitchWalletModal extends StatefulWidget {
  final WalletLogic logic;

  const SwitchWalletModal({Key? key, required this.logic}) : super(key: key);

  @override
  SwitchWalletModalState createState() => SwitchWalletModalState();
}

class SwitchWalletModalState extends State<SwitchWalletModal> {
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      widget.logic.loadDBWallets();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCreate(BuildContext context) async {
    final navigator = GoRouter.of(context);

    final name = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => TextInputModal(
        title: 'Create Wallet',
        placeholder: 'Enter wallet name',
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final address = await widget.logic.createWallet(name);

    if (address == null) {
      return;
    }

    await widget.logic.openWalletFromDB(address);

    HapticFeedback.heavyImpact();

    navigator.pop();
  }

  void handleEdit(BuildContext context, String address, String name) async {
    final option = await showCupertinoModalPopup<String?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoActionSheet(
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.of(dialogContext).pop('edit');
                },
                child: const Text('Edit'),
              ),
              // CupertinoActionSheetAction(
              //   isDestructiveAction: true,
              //   onPressed: () {
              //     Navigator.of(dialogContext).pop('delete');
              //   },
              //   child: const Text('Delete'),
              // ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
          );
        });

    if (option == null) {
      return;
    }

    if (option == 'edit') {
      final newName = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => TextInputModal(
          title: 'Edit Wallet',
          placeholder: 'Enter wallet name',
          initialValue: name,
        ),
      );

      if (newName == null || newName.isEmpty) {
        return;
      }

      await widget.logic.editWallet(address, newName);

      HapticFeedback.heavyImpact();
    }
  }

  void handleWalletTap(String address) async {
    final navigator = GoRouter.of(context);

    await widget.logic.openWalletFromDB(address);

    HapticFeedback.heavyImpact();

    navigator.pop();
  }

  Future<void> handleRefresh() async {
    await widget.logic.loadDBWallets();

    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final dbWalletsLoading = context.select<WalletState, bool>(
      (state) => state.dbWalletsLoading,
    );

    final dbWallets = context.select<WalletState, List<DBWallet>>(
      (state) => state.dbWallets,
    );

    return DismissibleModalPopup(
      modalKey: 'send-form',
      maxHeight: height,
      paddingSides: 10,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      onDismissed: (_) => handleDismiss(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
          child: SafeArea(
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  title: 'Wallets',
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          CupertinoSliverRefreshControl(
                            onRefresh: handleRefresh,
                          ),
                          if (dbWalletsLoading && dbWallets.isEmpty)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                childCount: 1,
                                (context, index) {
                                  return CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  );
                                },
                              ),
                            ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              childCount: dbWalletsLoading && dbWallets.isEmpty
                                  ? 0
                                  : dbWallets.length,
                              (context, index) {
                                final wallet = dbWallets[index];

                                return WalletRow(
                                  key: Key(wallet.address),
                                  wallet,
                                  onTap: () => handleWalletTap(wallet.address),
                                  onMore: () => handleEdit(
                                      context, wallet.address, wallet.name),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Button(
                          text: 'Create Wallet',
                          onPressed: () => handleCreate(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
