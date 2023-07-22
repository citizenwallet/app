import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final WalletLogic logic;

  const ProfileScreen({
    Key? key,
    required this.logic,
  }) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

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

  void handleEdit() {
    print('edit');
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    if (wallet == null) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        child: SafeArea(
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
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const ProfileCircle(
                              size: 160,
                              imageUrl: 'assets/icons/profile.svg',
                              backgroundColor: ThemeColors.white,
                              borderColor: ThemeColors.subtle,
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
                                  onPressed: () => handleCopy(wallet.account),
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
                                  text: 'Edit',
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
