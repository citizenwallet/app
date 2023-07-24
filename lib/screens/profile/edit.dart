import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profile/logic.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    Key? key,
  }) : super(key: key);

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  late ProfileLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = ProfileLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
    });
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCopy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    HapticFeedback.lightImpact();
  }

  void handleSave(String image) async {
    final navigator = GoRouter.of(context);

    HapticFeedback.lightImpact();

    await _logic.save(ProfileV1(image: image));

    HapticFeedback.heavyImpact();
    navigator.pop();
  }

  void handleSelectPhoto() {
    HapticFeedback.lightImpact();

    _logic.selectPhoto();
  }

  @override
  Widget build(BuildContext context) {
    final editingImage =
        context.select((ProfileState state) => state.editingImage);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: 'Edit',
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
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                ProfileCircle(
                                  size: 160,
                                  imageUrl: editingImage ??
                                      'assets/icons/profile.svg',
                                  backgroundColor: ThemeColors.white,
                                  borderColor: ThemeColors.subtle,
                                ),
                                CupertinoButton(
                                  onPressed: handleSelectPhoto,
                                  padding: const EdgeInsets.all(0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: ThemeColors.backgroundTransparent
                                          .resolveFrom(context),
                                      borderRadius: BorderRadius.circular(80),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    height: 160,
                                    width: 160,
                                    child: Center(
                                      child: Icon(
                                        CupertinoIcons.photo,
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 44,
                                ),
                                Text(
                                  '@chicken.little',
                                  style: TextStyle(
                                    color: ThemeColors.subtleText
                                        .resolveFrom(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                CupertinoButton(
                                  child: Icon(
                                    CupertinoIcons.square_on_square,
                                    size: 14,
                                    color: ThemeColors.touchable
                                        .resolveFrom(context),
                                  ),
                                  onPressed: () =>
                                      handleCopy('@chicken.little'),
                                )
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Robust Chicken',
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
                                    'Loves to support the community at the local farmers market 🚜.',
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
                                Button(
                                  text: 'Save',
                                  color: ThemeColors.surfacePrimary
                                      .resolveFrom(context),
                                  labelColor: ThemeColors.black,
                                  onPressed: () =>
                                      handleSave(editingImage ?? ''),
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
