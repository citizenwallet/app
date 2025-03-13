import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/modals/wallet/community_picker.dart';
import 'package:citizenwallet/screens/wallet/wallet_row.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/communities/logic.dart';
import 'package:citizenwallet/state/communities/selectors.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/expansion_panel/expansion_panel.dart';
import 'package:citizenwallet/widgets/export_wallet_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/scanner/scanner_modal.dart';
import 'package:citizenwallet/widgets/text_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountsScreen extends StatefulWidget {
  final WalletLogic logic;
  final String? currentAddress;

  const AccountsScreen({
    super.key,
    required this.logic,
    this.currentAddress,
  });

  @override
  AccountsScreenState createState() => AccountsScreenState();
}

class AccountsScreenState extends State<AccountsScreen> {
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  final ScrollController _scrollController = ScrollController();

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

    widget.logic.loadDBWallets();
    _profilesLogic.loadProfilesFromAllAccounts();
  }

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    GoRouter.of(context).pop();
  }

  void handleJoin(BuildContext context) async {
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

  void handleCreate(BuildContext context, String? alias) async {
    final navigator = GoRouter.of(context);

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
                  child: Text(
                    AppLocalizations.of(context)!.editname,
                    style: TextStyle(
                      color:
                          Theme.of(context).colors.primary.resolveFrom(context),
                    ),
                  ),
                ),
              if (!locked)
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(dialogContext).pop('export');
                  },
                  child: Text(
                    AppLocalizations.of(context)!.export,
                    style: TextStyle(
                      color:
                          Theme.of(context).colors.primary.resolveFrom(context),
                    ),
                  ),
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
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(
                  color: Theme.of(context).colors.primary.resolveFrom(context),
                ),
              ),
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

  void handleProfileEdit() async {
    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (context) => const EditProfileModal(),
    );
  }

  void handleGoToSettings(BuildContext context) {
    GoRouter.of(context).push('/settings');
  }

  void handleLoadProfile(String address) {
    _profilesLogic.loadProfile(address);
  }

  void handleScrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentWallet = context.select((WalletState state) => state.wallet);

    final cwWalletsLoading = context.select<WalletState, bool>(
      (state) => state.cwWalletsLoading,
    );

    final wallets = context.watch<WalletState>().wallets;
    final groupedWallets = context.select(selectSortedGroupedWalletsByAlias);

    final communities = context.select(selectMappedCommunityConfigs);

    final singleCommunityMode = context.select(
      (AppState state) => state.singleCommunityMode,
    );

    final profiles = context.watch<ProfilesState>().profiles;

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
                showBackButton: true,
                title: AppLocalizations.of(context)!.accounts,
              ),
              Expanded(
                child: Stack(
                  children: [
                    CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        if (currentWallet != null)
                          SliverPersistentHeader(
                            pinned: true,
                            floating: false,
                            delegate: PersistentHeaderDelegate(
                              expandedHeight: 180,
                              minHeight: 100,
                              builder: (context, shrink) => GestureDetector(
                                onTap: handleScrollToTop,
                                child: Container(
                                  color: Theme.of(context)
                                      .colors
                                      .uiBackgroundAlt
                                      .resolveFrom(context),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        bottom: 24,
                                        left: 0,
                                        right: 0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Opacity(
                                              opacity: progressiveClamp(
                                                0,
                                                1,
                                                shrink * 4,
                                              ),
                                              child: CupertinoButton(
                                                padding:
                                                    const EdgeInsets.all(5),
                                                onPressed: () =>
                                                    handleGoToSettings(context),
                                                child: Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colors
                                                          .primary
                                                          .resolveFrom(context),
                                                    ),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .settings,
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colors
                                                                  .primary
                                                                  .resolveFrom(
                                                                      context),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Icon(
                                                        CupertinoIcons.settings,
                                                        color: Theme.of(context)
                                                            .colors
                                                            .primary
                                                            .resolveFrom(
                                                                context),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        color: Theme.of(context)
                                            .colors
                                            .uiBackgroundAlt
                                            .resolveFrom(context),
                                        child: WalletRow(
                                          key: Key(
                                              '${currentWallet.account}_${currentWallet.alias}'),
                                          currentWallet,
                                          communities: communities,
                                          profiles: profiles,
                                          isSelected: true,
                                          bottomBorder: false,
                                          onProfileEdit: handleProfileEdit,
                                          onLoadProfile: handleLoadProfile,
                                          onTap: () => handleDismiss(context),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Theme.of(context)
                                              .colors
                                              .subtle
                                              .resolveFrom(context),
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 10,
                          ),
                        ),
                        if (cwWalletsLoading && groupedWallets.isEmpty)
                          SliverToBoxAdapter(
                            child: CupertinoActivityIndicator(
                              color: Theme.of(context)
                                  .colors
                                  .subtle
                                  .resolveFrom(context),
                            ),
                          ),
                        if (singleCommunityMode)
                          SliverList(
                              delegate: SliverChildBuilderDelegate(
                                  childCount: wallets.length, (context, index) {
                            final wallet = wallets[index];

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
                          })),
                        if (!singleCommunityMode && groupedWallets.isNotEmpty)
                          ...groupedWallets.entries.map((entry) {
                            final key = entry.key;
                            final cwWallets = entry.value;
                            final community = communities[key];

                            if (community == null) {
                              return const SliverToBoxAdapter(
                                child: SizedBox.shrink(),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == 0) {
                                    // Community header
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 16, 16, 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ProfileCircle(
                                            size: 30,
                                            imageUrl: community.logo,
                                            borderColor: Theme.of(context)
                                                .colors
                                                .transparent,
                                            backgroundColor:
                                                Theme.of(context).colors.white,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            community.name,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colors
                                                  .text
                                                  .resolveFrom(context),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  // Wallet rows
                                  final wallet = cwWallets[index - 1];
                                  return WalletRow(
                                    key: Key(
                                        '${wallet.account}_${wallet.alias}'),
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
                                childCount:
                                    cwWallets.length + 1, // +1 for the header
                              ),
                            );
                          }).toList(),
                        const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 120,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context)
                                  .withOpacity(0.0),
                              Theme.of(context)
                                  .colors
                                  .uiBackgroundAlt
                                  .resolveFrom(context),
                            ],
                          ),
                        ),
                      ),
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
                            color: Theme.of(context)
                                .colors
                                .uiBackground
                                .resolveFrom(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.importText,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.down_arrow,
                                  color: Theme.of(context)
                                      .colors
                                      .text
                                      .resolveFrom(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          CupertinoButton(
                            padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                            onPressed: singleCommunityMode
                                ? () =>
                                    handleCreate(context, currentWallet?.alias)
                                : () => handleJoin(context),
                            borderRadius: BorderRadius.circular(25),
                            color: Theme.of(context)
                                .colors
                                .surfacePrimary
                                .resolveFrom(context),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  singleCommunityMode
                                      ? AppLocalizations.of(context)!
                                          .createNewAccount
                                      : AppLocalizations.of(context)!
                                          .joinCommunity,
                                  style: TextStyle(
                                    color: Theme.of(context).colors.black,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  CupertinoIcons.plus,
                                  color: Theme.of(context).colors.black,
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
