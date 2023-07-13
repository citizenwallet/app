import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/export_wallet_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SwitchWalletModal extends StatefulWidget {
  final WalletLogic logic;
  final String? currentAddress;

  const SwitchWalletModal({
    Key? key,
    required this.logic,
    this.currentAddress,
  }) : super(key: key);

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
      builder: (modalContext) => const TextInputModal(
        title: 'Create Account',
        placeholder: 'Enter account name',
      ),
    );

    if (name == null || name.isEmpty) {
      return;
    }

    final address = await widget.logic.createWallet(name);

    if (address == null) {
      return;
    }

    HapticFeedback.heavyImpact();

    navigator.pop(address);
  }

  void handleMore(
    BuildContext context,
    String address,
    String name,
    bool locked,
  ) async {
    final wallet = context.read<WalletState>().wallet;

    HapticFeedback.heavyImpact();

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
                child: const Text('Edit name'),
              ),
              if (!locked)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('export');
                  },
                  child: const Text('Export'),
                ),
              if (wallet != null && wallet.address != address)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('delete');
                  },
                  child: const Text('Delete'),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(widget.currentAddress);
              },
              child: const Text('Cancel'),
            ),
          );
        });

    if (option == null) {
      return;
    }

    HapticFeedback.lightImpact();

    if (option == 'edit') {
      final newName = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => TextInputModal(
          title: 'Edit Account',
          placeholder: 'Enter account name',
          initialValue: name,
        ),
      );

      if (newName == null || newName.isEmpty) {
        return;
      }

      await widget.logic.editWallet(address, newName);

      HapticFeedback.heavyImpact();
      return;
    }

    if (option == 'export') {
      final privateKey = await widget.logic.returnWallet(address);

      if (privateKey == null) {
        return;
      }

      await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ExportWalletModal(
          title: 'Export Account',
          toCopy: '-----------',
          onCopy: () => handleCopyWalletPrivateKey(privateKey),
        ),
      );

      return;
    }

    if (option == 'delete') {
      final confirm = await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: 'Delete account',
          details: [
            'Are you sure you want to delete this account?',
            'This action cannot be undone.',
          ],
        ),
      );

      if (confirm == null || !confirm) {
        return;
      }

      await widget.logic.deleteWallet(address);
    }
  }

  void handleCopyWalletPrivateKey(String privateKey) {
    Clipboard.setData(ClipboardData(text: privateKey));

    HapticFeedback.heavyImpact();
  }

  void handleImport(BuildContext context) async {
    final navigator = GoRouter.of(context);

    final result = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Scanner(
        modalKey: 'import-wallet-wallet-list-scanner',
        confirm: true,
      ),
    );

    if (result == null) {
      return;
    }

    final newName = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => const TextInputModal(
        title: 'Edit Account',
        placeholder: 'Enter account name',
        initialValue: 'New Account',
      ),
    );

    final address =
        await widget.logic.importWallet(result, newName ?? 'New Account');

    if (address == null) {
      return;
    }

    HapticFeedback.heavyImpact();

    navigator.pop(address);
  }

  void handleWalletTap(String address) async {
    final navigator = GoRouter.of(context);

    HapticFeedback.heavyImpact();

    navigator.pop(address);
  }

  Future<void> handleRefresh() async {
    await widget.logic.loadDBWallets();

    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final cwWalletsLoading = context.select<WalletState, bool>(
      (state) => state.cwWalletsLoading,
    );

    final cwWallets = context.watch<WalletState>().wallets;

    return DismissibleModalPopup(
      modaleKey: 'switch-wallet-modal',
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
                  title: 'Accounts',
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
                          if (cwWalletsLoading && cwWallets.isEmpty)
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
                              childCount: cwWalletsLoading && cwWallets.isEmpty
                                  ? 0
                                  : cwWallets.length,
                              (context, index) {
                                final wallet = cwWallets[index];

                                return WalletRow(
                                  key: Key(wallet.address),
                                  wallet,
                                  isSelected:
                                      widget.currentAddress == wallet.address,
                                  onTap: () => handleWalletTap(wallet.address),
                                  onMore: () => handleMore(
                                    context,
                                    wallet.address,
                                    wallet.name,
                                    wallet.locked,
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
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          children: [
                            Button(
                              text: 'Create Account',
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              labelColor: ThemeColors.black,
                              onPressed: () => handleCreate(context),
                            ),
                            const SizedBox(height: 10),
                            Button(
                              text: 'Import Account',
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              labelColor: ThemeColors.black,
                              onPressed: () => handleImport(context),
                            ),
                          ],
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
