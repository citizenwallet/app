import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/modals/wallet/switch_wallet_modal.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  final String? address;
  final WalletLogic wallet;

  const AccountScreen({
    Key? key,
    required this.address,
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
    super.dispose();
  }

  void onLoad() async {
    if (widget.address == null) {
      return;
    }

    await _walletLogic.openWallet(widget.address!, (bool hasChanged) async {
      if (hasChanged) _logic.loadProfile();
    });
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

    final address =
        await CupertinoScaffold.showCupertinoModalBottomSheet<String?>(
      context: context,
      expand: true,
      useRootNavigator: true,
      builder: (modalContext) => SwitchWalletModal(
        logic: _walletLogic,
        currentAddress: widget.address,
      ),
    );

    if (address == null || address == _walletLogic.address) {
      return;
    }

    _walletLogic.cleanupWalletState();

    await delay(const Duration(milliseconds: 250));

    navigator.go('/account/$address');

    await delay(const Duration(milliseconds: 50));

    onLoad();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final safePadding = MediaQuery.of(context).padding.top;

    final wallet = context.select((WalletState state) => state.wallet);
    final loading = context.select((WalletState state) => state.loading);
    final cleaningUp = context.select((WalletState state) => state.cleaningUp);
    final firstLoad = context.select((WalletState state) => state.firstLoad);
    final transactionSendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    final profile = context.watch<ProfileState>();

    final profileLoading = loading || profile.loading;

    final hasNoProfile =
        profile.username == '' && profile.name == '' && profile.image == '';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(10, safePadding + 60, 10, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ListView(
                      controller: ModalScrollController.of(context),
                      physics:
                          const ScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        SizedBox(
                          height: 400,
                          width: width,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: ThemeColors.white.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  40,
                                  40,
                                  40,
                                  (profileLoading || hasNoProfile) ? 40 : 60,
                                ),
                                margin: const EdgeInsets.only(top: 80),
                                child: PrettyQr(
                                  data: widget.address ?? '',
                                  size: 200,
                                  roundEdges: false,
                                ),
                              ),
                              Positioned(
                                top: 10,
                                child: profileLoading
                                    ? const PulsingContainer(
                                        height: 100,
                                        width: 100,
                                        borderRadius: 50,
                                      )
                                    : ProfileCircle(
                                        size: 100,
                                        imageUrl: profile.imageMedium,
                                        borderColor: ThemeColors.subtle,
                                      ),
                              ),
                              if (!hasNoProfile && !profileLoading)
                                Positioned(
                                  bottom: 16,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 44,
                                      ),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 200,
                                        ),
                                        child: Text(
                                          '@${profile.username}',
                                          style: TextStyle(
                                            color: ThemeColors.black
                                                .resolveFrom(context),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      CupertinoButton(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 0, 0, 0),
                                        child: Icon(
                                          CupertinoIcons.square_on_square,
                                          size: 14,
                                          color: ThemeColors.black
                                              .resolveFrom(context),
                                        ),
                                        onPressed: () =>
                                            handleCopy('@${profile.username}'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!hasNoProfile && !profileLoading)
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
                        if (!profileLoading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  hasNoProfile
                                      ? "It looks like you don't have a profile yet."
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
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  if (!profileLoading)
                    Positioned(
                      bottom: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          profileLoading
                              ? CupertinoActivityIndicator(
                                  color:
                                      ThemeColors.subtle.resolveFrom(context),
                                )
                              : Button(
                                  text: hasNoProfile ? 'Create' : 'Edit',
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  labelColor: ThemeColors.black,
                                  onPressed: handleEdit,
                                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
