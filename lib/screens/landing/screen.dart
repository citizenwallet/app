import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/screen_description.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  LandingScreenState createState() => LandingScreenState();
}

class LandingScreenState extends State<LandingScreen> {
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
                    label: 'New Wallet',
                    onPressed: () => GoRouter.of(context).go('/wallet'),
                    minWidth: 200,
                    maxWidth: 200,
                  ),
                  const SizedBox(height: 20),
                  Button(
                    label: 'Restore a wallet',
                    onPressed: () => GoRouter.of(context).go('/wallet'),
                    minWidth: 200,
                    maxWidth: 200,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
