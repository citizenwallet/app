import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/screen_description.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);
    });
  }

  void handleNewWallet() {
    _appLogic.setFirstLaunch(false);

    GoRouter.of(context).go('/wallets');
  }

  void handleRestoreWallet() {
    _appLogic.setFirstLaunch(false);

    GoRouter.of(context).go('/wallets');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Flex(
          direction: Axis.vertical,
          children: [
            ScreenDescription(
              topPadding: 0,
              title: Text(
                'Citizen Wallet',
                style: TextStyle(
                  color: ThemeColors.text.resolveFrom(context),
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              heading: Text(
                'Create and manage your own currencies',
                style: TextStyle(
                  color: ThemeColors.text.resolveFrom(context),
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              image: SvgPicture.asset(
                'assets/wallet.svg',
                semanticsLabel: 'A wallet',
                height: 140,
                width: 140,
              ),
              action: Column(
                children: [
                  Button(
                    text: 'New Wallet',
                    onPressed: handleNewWallet,
                    minWidth: 200,
                    maxWidth: 200,
                  ),
                  const SizedBox(height: 20),
                  Button(
                    text: 'Restore a wallet',
                    onPressed: handleRestoreWallet,
                    minWidth: 200,
                    maxWidth: 200,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
