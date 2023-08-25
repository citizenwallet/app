import 'package:citizenwallet/modals/profile/edit.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
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

class ProfileModal extends StatefulWidget {
  final String account;
  final bool readonly;

  const ProfileModal({
    Key? key,
    required this.account,
    this.readonly = false,
  }) : super(key: key);

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
    _logic.clearProfileLink();
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
    final width = MediaQuery.of(context).size.width;

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
                        color: ThemeColors.touchable.resolveFrom(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ListView(
                          controller: ModalScrollController.of(context),
                          physics: const ScrollPhysics(
                              parent: BouncingScrollPhysics()),
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
                                      color: ThemeColors.white
                                          .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: EdgeInsets.fromLTRB(
                                      40,
                                      40,
                                      40,
                                      (loading || hasNoProfile) ? 40 : 60,
                                    ),
                                    margin: const EdgeInsets.only(top: 80),
                                    child: AnimatedOpacity(
                                      opacity: profileLinkLoading ? 0 : 1,
                                      duration:
                                          const Duration(milliseconds: 250),
                                      child: PrettyQr(
                                        data: profileLink,
                                        size: 200,
                                        roundEdges: false,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    child: loading
                                        ? const PulsingContainer(
                                            height: 100,
                                            width: 100,
                                            borderRadius: 50,
                                          )
                                        : ProfileCircle(
                                            size: 100,
                                            imageUrl: profile?.imageMedium,
                                            borderColor: ThemeColors.subtle,
                                          ),
                                  ),
                                  if (!hasNoProfile && !loading)
                                    Positioned(
                                      bottom: 16,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                            onPressed: () => handleCopy(
                                                '@${profile.username}'),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
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
                                        color: ThemeColors.text
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
                                          ? "It looks like you don't have a profile yet."
                                          : profile.description,
                                      style: TextStyle(
                                        color: ThemeColors.text
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
                                      color: ThemeColors.subtle
                                          .resolveFrom(context),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
