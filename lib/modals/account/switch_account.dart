import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/state/communities/logic.dart';
import 'package:citizenwallet/state/communities/selectors.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SwitchAccountModal extends StatefulWidget {
  final WalletLogic logic;
  final String? currentAddress;

  const SwitchAccountModal({
    super.key,
    required this.logic,
    this.currentAddress,
  });

  @override
  SwitchAccountModalState createState() => SwitchAccountModalState();
}

class SwitchAccountModalState extends State<SwitchAccountModal> {
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  late ProfilesLogic _profilesLogic;
  late CommunitiesLogic _communitiesLogic;

  @override
  void initState() {
    super.initState();

    _profilesLogic = ProfilesLogic(context);
    _communitiesLogic = CommunitiesLogic(context);

    WidgetsBinding.instance.addObserver(_profilesLogic);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_profilesLogic);

    _profilesLogic.dispose();

    super.dispose();
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    _communitiesLogic.fetchCommunities();

    await widget.logic.loadDBWallets();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    GoRouter.of(context).pop();
  }

  void handleCreate(BuildContext context) async {
    final navigator = GoRouter.of(context);

    final alias =
        await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      builder: (modalContext) => const CommunityPickerModal(),
    );

    if (alias == null || alias.isEmpty) {
      return;
    }

    final address = await widget.logic.createWallet(alias);

    if (address == null) {
      return;
    }

    HapticFeedback.heavyImpact();

    navigator.pop((address, alias));
  }

  void handleMore(
    BuildContext context,
    String address,
    String alias,
    String name,
    bool locked,
    bool hasProfile,
  ) async {
    final wallet = context.read<WalletState>().wallet;

    HapticFeedback.heavyImpact();

    final option = await showCupertinoModalPopup<String?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoActionSheet(
            actions: [
              if (!hasProfile)
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('edit');
                  },
                  child: Text(AppLocalizations.of(context)!.editname),
                ),
              if (!locked)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('export');
                  },
                  child: Text(AppLocalizations.of(context)!.export),
                ),
              if (wallet != null && wallet.account != address)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('delete');
                  },
                  child: Text(AppLocalizations.of(context)!.delete),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop(widget.currentAddress);
              },
              child: Text(AppLocalizations.of(context)!.cancel),
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
          title: AppLocalizations.of(context)!.editname,
          placeholder: AppLocalizations.of(context)!.enteraccountname,
          initialValue: name,
        ),
      );

      if (newName == null || newName.isEmpty) {
        return;
      }

      await widget.logic.editWallet(address, alias, newName);

      HapticFeedback.heavyImpact();
      return;
    }

    if (option == 'export') {
      final webWalletUrl = await widget.logic.returnWallet(address, alias);

      if (webWalletUrl == null) {
        return;
      }

      await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ExportWalletModal(
          title: AppLocalizations.of(context)!.exportAccount,
          toCopy: '-----------',
          onCopy: () => handleExportWallet(webWalletUrl),
        ),
      );

      return;
    }

    if (option == 'delete') {
      final confirm = await showCupertinoModalPopup(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: AppLocalizations.of(context)!.deleteaccount,
          details: [
            AppLocalizations.of(context)!.deleteaccountMsg1,
            AppLocalizations.of(context)!.deleteaccountMsg2,
          ],
        ),
      );

      if (confirm == null || !confirm) {
        return;
      }

      await widget.logic.deleteWallet(address, alias);
    }
  }

  void handleExportWallet(String webWalletUrl) {
    Clipboard.setData(ClipboardData(text: webWalletUrl));

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

    final alias =
        await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      builder: (modalContext) => const CommunityPickerModal(),
    );

    if (alias == null || alias.isEmpty) {
      return;
    }

    final address = await widget.logic.importWallet(result, alias);

    if (address == null) {
      return;
    }

    HapticFeedback.heavyImpact();

    navigator.pop((address, alias));
  }

  void handleWalletTap(String address, String alias) async {
    final navigator = GoRouter.of(context);

    HapticFeedback.heavyImpact();

    navigator.pop((address, alias));
  }

  void handleLoadProfile(String address) {
    _profilesLogic.loadProfile(address);
  }

  void handleGoToSettings(BuildContext context) {
    GoRouter.of(context).push('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final cwWalletsLoading = context.select<WalletState, bool>(
      (state) => state.cwWalletsLoading,
    );
    final width = MediaQuery.of(context).size.width;
    final cwWallets = context.select(selectSortedWalletsByAlias);

    final communities = context.select(selectMappedCommunityConfigs);

    final profiles = context.watch<ProfilesState>().profiles;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.background.resolveFrom(context),
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
              Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Header(
                    color: ThemeColors.background,
                    titleWidget: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Icon(
                            CupertinoIcons.arrow_left,
                            color: ThemeColors.touchable.resolveFrom(context),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.accounts,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8F899C),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
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
                                key: Key('${wallet.account}_${wallet.alias}'),
                                wallet,
                                communities: communities,
                                profiles: profiles,
                                isSelected:
                                    widget.currentAddress == wallet.account,
                                onTap: () => handleWalletTap(
                                  wallet.account,
                                  wallet.alias,
                                ),
                                onMore: () => handleMore(
                                  context,
                                  wallet.account,
                                  wallet.alias,
                                  wallet.name,
                                  wallet.locked,
                                  profiles.containsKey(wallet.account),
                                ),
                                onLoadProfile: handleLoadProfile,
                              );
                            },
                          ),
                        ),
                        // const SliverToBoxAdapter(
                        //   child: SizedBox(
                        //     height: 120,
                        //   ),
                        // ),
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                onPressed: () => handleCreate(context),
                                borderRadius: BorderRadius.circular(25),
                                color: ThemeColors.uiBackground
                                    .resolveFrom(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .joinCommunity,
                                      style: const TextStyle(
                                        color: ThemeColors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      CupertinoIcons.plus,
                                      color: ThemeColors.black,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                onPressed: () => handleImport(context),
                                borderRadius: BorderRadius.circular(25),
                                color: ThemeColors.uiBackground
                                    .resolveFrom(context),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.importText,
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Icon(
                                      CupertinoIcons.down_arrow,
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 20,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoButton(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 5, 15, 5),
                                onPressed: () => handleGoToSettings(context),
                                child: Container(
                                  height: 40,
                                  width: width * 0.4,
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: ThemeColors.surfacePrimary
                                          .resolveFrom(context),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .appSettings,
                                        style: TextStyle(
                                          color: ThemeColors.surfacePrimary
                                              .resolveFrom(context),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        CupertinoIcons.settings,
                                        color: ThemeColors.surfacePrimary
                                            .resolveFrom(context),
                                        size: 15,
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
