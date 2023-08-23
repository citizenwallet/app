import 'package:async/async.dart';
import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/export_wallet_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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

  CancelableOperation<void>? _operation;

  late ProfileLogic _logic;
  late ProfilesLogic _profilesLogic;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);
    _profilesLogic = ProfilesLogic(context);

    WidgetsBinding.instance.addObserver(_profilesLogic);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    if (_operation != null) {
      _operation!.cancel();
    }

    WidgetsBinding.instance.removeObserver(_profilesLogic);

    _profilesLogic.dispose();

    super.dispose();
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _operation = await widget.logic.loadDBWallets();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

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
      builder: (_) => const ScannerModal(
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

    _logic.resetAll();

    navigator.pop(address);
  }

  void handleLoadProfile(String address) {
    _profilesLogic.loadProfile(address);
  }

  @override
  Widget build(BuildContext context) {
    final cwWalletsLoading = context.select<WalletState, bool>(
      (state) => state.cwWalletsLoading,
    );

    final cwWallets = context.watch<WalletState>().wallets;

    final profiles = context.watch<ProfilesState>().profiles;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
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
                      controller: ModalScrollController.of(context),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
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
                                profiles: profiles,
                                isSelected:
                                    widget.currentAddress == wallet.address,
                                onTap: () => handleWalletTap(wallet.address),
                                onMore: () => handleMore(
                                  context,
                                  wallet.address,
                                  wallet.name,
                                  wallet.locked,
                                ),
                                onLoadProfile: handleLoadProfile,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            onPressed: () => handleImport(context),
                            borderRadius: BorderRadius.circular(25),
                            color:
                                ThemeColors.uiBackground.resolveFrom(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Import',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.down_arrow,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CupertinoButton(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            onPressed: () => handleCreate(context),
                            borderRadius: BorderRadius.circular(25),
                            color:
                                ThemeColors.surfacePrimary.resolveFrom(context),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Create',
                                  style: TextStyle(
                                    color: ThemeColors.black,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.plus,
                                  color: ThemeColors.black,
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
            ],
          ),
        ),
      ),
    );
  }
}
