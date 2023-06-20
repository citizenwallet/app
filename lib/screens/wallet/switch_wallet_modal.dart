import 'dart:convert';

import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/export_qr_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

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
    GoRouter.of(context).pop(widget.currentAddress);
  }

  void handleCreate(BuildContext context) async {
    final navigator = GoRouter.of(context);

    final name = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => const TextInputModal(
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

    // await widget.logic.openWalletFromDB(address);

    HapticFeedback.heavyImpact();

    navigator.pop(address);
  }

  void handleMore(
      BuildContext context, String address, String name, bool locked) async {
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
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(dialogContext).pop(locked ? 'unlock' : 'lock');
                },
                child: Text(locked ? 'Unlock' : 'Lock'),
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
      return;
    }

    if (option == 'lock') {
      final password = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => const TextInputModal(
          title: 'Set Password',
          placeholder: 'Enter wallet password',
          secure: true,
          confirm: true,
        ),
      );

      if (password == null || password.isEmpty) {
        return;
      }

      await widget.logic.lockWallet(address, password);

      HapticFeedback.heavyImpact();
      return;
    }

    if (option == 'unlock') {
      final password = await showCupertinoModalPopup<String?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => const TextInputModal(
          title: 'Enter Password',
          placeholder: 'Enter wallet password',
          secure: true,
        ),
      );

      if (password == null || password.isEmpty) {
        return;
      }

      await widget.logic.unlockWallet(address, password);

      HapticFeedback.heavyImpact();
      return;
    }

    if (option == 'export') {
      final int pin = getRandomNumber(len: 12);

      final qrWallet = await widget.logic.lockAndReturnWallet(address, '$pin');

      if (qrWallet == null) {
        return;
      }

      final compressedWallet = qrWallet.toCompressedJson();

      await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ExportQRModal(
          title: 'Export Wallet',
          qrCode: compressedWallet,
          secureCode: '$pin',
          toCopy: '---------',
          onCopy: () => handleCopyWalletPrivateKey(qrWallet, '$pin'),
        ),
      );

      return;
    }
  }

  void handleCopyWalletPrivateKey(QRWallet qrWallet, String password) {
    final Wallet wallet =
        Wallet.fromJson(jsonEncode(qrWallet.data.wallet), password);

    final privateKey = wallet.privateKey;

    Clipboard.setData(ClipboardData(text: bytesToHex(privateKey.privateKey)));

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
        title: 'Edit Wallet',
        placeholder: 'Enter wallet name',
        initialValue: 'New Wallet',
      ),
    );

    final address =
        await widget.logic.importWallet(result, newName ?? 'New Wallet');

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

    final dbWalletsLoading = context.select<WalletState, bool>(
      (state) => state.dbWalletsLoading,
    );

    final dbWallets = context.select<WalletState, List<DBWallet>>(
      (state) => state.dbWallets,
    );

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
                              text: 'Create Wallet',
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              labelColor: ThemeColors.black,
                              onPressed: () => handleCreate(context),
                            ),
                            const SizedBox(height: 10),
                            Button(
                              text: 'Import Wallet',
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
