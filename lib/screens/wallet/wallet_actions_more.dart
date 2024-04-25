import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/selectors.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

class WalletActionsMore extends StatelessWidget {
  final ScrollController controller = ScrollController();

  final double shrink;
  final bool refreshing;
  final bool isOpened;

  WalletActionsMore(
      {super.key,
      this.shrink = 0,
      this.refreshing = false,
      this.isOpened = false});

  bool _showAdditionalButtons = false;
  void handleOpenAbout() {
    _showAdditionalButtons = !_showAdditionalButtons;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    void handleClick(String value) {
      switch (value) {
        case 'Logout':
          break;
        case 'Settings':
          break;
      }
    }

    return Stack(
      children: [
        SafeArea(
          top: false,
          bottom: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            height: isOpened ? 0 : 180,
            decoration: const BoxDecoration(
              color: ThemeColors.black,
              gradient: LinearGradient(
                colors: [
                  ThemeColors.background,
                  ThemeColors.background,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.all(Radius.circular(0.0)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              width: 2,
                            ),
                          ),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Icon(
                              CupertinoIcons.plus,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "Top up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              width: 2,
                            ),
                          ),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Icon(
                              CupertinoIcons.ellipsis,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "Custom Action",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoButton(
                        onPressed: null,
                        padding: EdgeInsets.zero,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              width: 2,
                            ),
                          ),
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Icon(
                              CupertinoIcons.person_2,
                              color: ThemeColors.surfacePrimary
                                  .resolveFrom(context),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        width: 250,
                        height: 40,
                        child: const Text(
                          "View Community Dashboard",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.black,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
