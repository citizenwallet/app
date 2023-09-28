import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/modals/account/switch_account.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_qr_badge.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  final String? address;
  final String? alias;
  final WalletLogic wallet;

  const AccountScreen({
    Key? key,
    required this.address,
    required this.alias,
    required this.wallet,
  }) : super(key: key);

  @override
  AccountScreenState createState() => AccountScreenState();
}

class AccountScreenState extends State<AccountScreen> {
  late ProfileLogic _logic;
  late WalletLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);
    _walletLogic = widget.wallet;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.clearProfileLink();

    super.dispose();
  }

  void onLoad() async {
    if (widget.address == null || widget.alias == null) {
      return;
    }

    await _walletLogic.openWallet(
      widget.address,
      widget.alias,
      (bool hasChanged) async {
        await _logic.loadProfileLink();

        if (hasChanged) {
          _logic.resetAll();
          _logic.loadProfile();
        }
      },
    );
  }

  void handleDismiss(BuildContext context) {
    _logic.resetViewProfile();
    GoRouter.of(context).pop();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.lightImpact();
  }

  void handleEdit() async {
    await CupertinoScaffold.showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (context) => const EditProfileModal(),
    );
  }

  void handleSwitchWalletModal(BuildContext context) async {
    HapticFeedback.mediumImpact();

    final navigator = GoRouter.of(context);

    final wallet = await CupertinoScaffold.showCupertinoModalBottomSheet<
        (String, String)?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => CupertinoScaffold(
        topRadius: const Radius.circular(40),
        transitionBackgroundColor: ThemeColors.transparent,
        body: SwitchAccountModal(
          logic: _walletLogic,
          currentAddress: widget.address,
        ),
      ),
    );

    if (wallet == null) {
      return;
    }

    final (address, alias) = wallet;

    if (address == _walletLogic.address) {
      return;
    }

    _walletLogic.cleanupWalletState();

    navigator.go('/account/$address?alias=$alias');

    await delay(const Duration(milliseconds: 50));

    onLoad();
  }

  void handleGoToSettings(BuildContext context) {
    GoRouter.of(context).push('/settings');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final safePadding = MediaQuery.of(context).padding.top;

    final wallet = context.select((WalletState state) => state.wallet);
    final loading = context.select((WalletState state) => state.loading);
    final cleaningUp = context.select((WalletState state) => state.cleaningUp);
    final transactionSendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    final profile = context.watch<ProfileState>();

    final profileLoading = loading || profile.loading;

    final hasNoProfile =
        profile.username == '' && profile.name == '' && profile.image == '';

    final profileLink =
        context.select((ProfileState state) => state.profileLink);

    final profileLinkLoading =
        context.select((ProfileState state) => state.profileLinkLoading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, safePadding + 100, 10, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ListView(
                      controller: ModalScrollController.of(context),
                      physics:
                          const ScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        ProfileQRBadge(
                          profile: ProfileV1(
                            account: profile.account,
                            username: profile.username,
                            name: profile.name,
                            description: profile.description,
                            image: profile.image,
                            imageMedium: profile.imageMedium,
                            imageSmall: profile.imageSmall,
                          ),
                          profileLink: profileLink,
                          profileLinkLoading: profileLinkLoading,
                          handleCopy: handleCopy,
                        ),
                        const SizedBox(height: 20),
                        if (!hasNoProfile && !profileLoading && !cleaningUp)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        if (!profileLoading && !cleaningUp)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  hasNoProfile
                                      ? "Create a profile to make it easier for people to send you tokens."
                                      : profile.description,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        if (!profileLoading && !cleaningUp)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              profileLoading
                                  ? CupertinoActivityIndicator(
                                      color: ThemeColors.subtle
                                          .resolveFrom(context),
                                    )
                                  : CupertinoButton(
                                      onPressed: handleEdit,
                                      child: Text(
                                        hasNoProfile
                                            ? 'Create a profile'
                                            : 'Edit',
                                        style: TextStyle(
                                          color: ThemeColors.text
                                              .resolveFrom(context),
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                          decoration: TextDecoration.underline,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ],
                          ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Header(
                transparent: true,
                blur: true,
                color: ThemeColors.transparent,
                titleWidget: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: transactionSendLoading || cleaningUp
                      ? null
                      : () => handleSwitchWalletModal(context),
                  child: wallet == null
                      ? const PulsingContainer(
                          height: 30,
                          padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color:
                                ThemeColors.surfaceSubtle.resolveFrom(context),
                          ),
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            wallet.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: ThemeColors.text
                                                  .resolveFrom(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Icon(
                                CupertinoIcons.chevron_down,
                                color: transactionSendLoading || cleaningUp
                                    ? ThemeColors.subtle.resolveFrom(context)
                                    : ThemeColors.primary.resolveFrom(context),
                              ),
                            ],
                          ),
                        ),
                ),
                actionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(5),
                      onPressed: () => handleGoToSettings(context),
                      child: Icon(
                        CupertinoIcons.settings,
                        color: ThemeColors.primary.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
