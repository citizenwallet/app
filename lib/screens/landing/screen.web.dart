import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/screen_description.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  WebLandingScreenState createState() => WebLandingScreenState();
}

class WebLandingScreenState extends State<WebLandingScreen>
    with TickerProviderStateMixin {
  late AppLogic _appLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);

      onLoad();
    });
  }

  void onLoad() async {
    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 500));

    final lastEncodedWallet = await _appLogic.getLastEncodedWallet();

    if (lastEncodedWallet != null) {
      navigator.go('/wallet/$lastEncodedWallet');
      return;
    }

    final wallet = await _appLogic.createWebWallet();

    if (wallet == null) {
      return;
    }

    final qrWallet = wallet.toCompressedJson();

    navigator.go('/wallet/$qrWallet');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: Center(
                                child: Lottie.asset(
                                  'assets/lottie/chat.json',
                                  height: 300,
                                  width: 300,
                                  animate: true,
                                  repeat: true,
                                  // controller: _controller,
                                ),
                              ),
                            ),
                            Text(
                              'Citizen Wallet',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'The wallet for the rest of us',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
