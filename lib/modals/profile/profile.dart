import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/profile/profile_qr_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class ProfileModal extends StatefulWidget {
  final String account;
  final bool readonly;
  final bool keepLink;
  final WalletLogic? walletLogic;

  const ProfileModal({
    super.key,
    required this.account,
    this.readonly = false,
    this.keepLink = false,
    this.walletLogic,
  });

  @override
  ProfileModalState createState() => ProfileModalState();
}

class ProfileModalState extends State<ProfileModal> {
  late ProfileLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() async {
    await delay(const Duration(milliseconds: 250));

    await _logic.loadProfileLink();

    _logic.loadViewProfile(widget.account);
  }

  void handleDismiss(BuildContext context) {
    if (!widget.keepLink) {
      _logic.clearProfileLink();
    }

    _logic.resetViewProfile();
    GoRouter.of(context).pop();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.lightImpact();
  }

  void handleEdit() async {
    await showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (context) => const EditProfileModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>().viewProfile;

    final loading = context.watch<ProfileState>().viewLoading;

    final hasNoProfile = profile == null;

    final profileLink =
        context.select((ProfileState state) => state.profileLink);

    final profileLinkLoading =
        context.select((ProfileState state) => state.profileLinkLoading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      0,
                      10,
                      0,
                    ),
                    child: CupertinoButton(
                      padding: const EdgeInsets.all(5),
                      onPressed: () => handleDismiss(context),
                      child: Icon(
                        CupertinoIcons.xmark,
                        color: Theme.of(context)
                            .colors
                            .touchable
                            .resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ListView(
                      controller: ModalScrollController.of(context),
                      physics:
                          const ScrollPhysics(parent: BouncingScrollPhysics()),
                      children: [
                        ProfileQRBadge(
                          profile: profile,
                          profileLink: profileLink,
                          showQRCode: !profileLinkLoading,
                          handleCopy: handleCopy,
                        ),
                        const SizedBox(height: 20),
                        if (!hasNoProfile && !loading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),
                        if (!loading)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  hasNoProfile
                                      ? AppLocalizations.of(context)!
                                          .profileText1
                                      : profile.description,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
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
                    if (!widget.readonly)
                      Positioned(
                        bottom: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            loading
                                ? CupertinoActivityIndicator(
                                    color: Theme.of(context)
                                        .colors
                                        .subtle
                                        .resolveFrom(context),
                                  )
                                : CupertinoButton(
                                    onPressed: handleEdit,
                                    child: Text(
                                      hasNoProfile
                                          ? AppLocalizations.of(context)!.create
                                          : AppLocalizations.of(context)!.edit,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colors
                                            .text
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
