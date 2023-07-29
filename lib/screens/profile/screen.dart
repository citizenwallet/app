import 'package:citizenwallet/screens/profile/edit.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
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

  void onLoad() {
    _logic.loadProfile();
  }

  void handleDismiss(BuildContext context) {
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
      builder: (context) => const EditProfileScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileState>();

    final loading = profile.loading;

    final error = profile.error;

    final hasNoProfile = !loading && error && profile.username == '';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: 'Profile',
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: ListView(
                          controller: ModalScrollController.of(context),
                          physics: const ScrollPhysics(
                              parent: BouncingScrollPhysics()),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ProfileCircle(
                                  size: 160,
                                  imageUrl: profile.image != ''
                                      ? profile.image
                                      : 'assets/icons/profile.svg',
                                  backgroundColor: ThemeColors.white,
                                  borderColor: ThemeColors.subtle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!hasNoProfile)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 44,
                                  ),
                                  ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 200),
                                    child: Text(
                                      '@${profile.username}',
                                      style: TextStyle(
                                        color: ThemeColors.subtleText
                                            .resolveFrom(context),
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                    child: Icon(
                                      CupertinoIcons.square_on_square,
                                      size: 14,
                                      color: ThemeColors.touchable
                                          .resolveFrom(context),
                                    ),
                                    onPressed: () =>
                                        handleCopy('@${profile.username}'),
                                  ),
                                ],
                              ),
                            if (!hasNoProfile)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    profile.name,
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
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
                            const SizedBox(height: 60),
                            Row(
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
                          ],
                        ),
                      )
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
