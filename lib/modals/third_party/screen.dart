import 'package:citizenwallet/state/third_party/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ThirdPartyModal extends StatefulWidget {
  final String url;
  final String account;
  final String alias;

  final WalletLogic walletLogic;

  const ThirdPartyModal({
    Key? key,
    required this.url,
    required this.account,
    required this.alias,
    required this.walletLogic,
  }) : super(key: key);

  @override
  ThirdPartyModalState createState() => ThirdPartyModalState();
}

class ThirdPartyModalState extends State<ThirdPartyModal> {
  late ThirdPartyLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = ThirdPartyLogic(context);

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    //
    super.dispose();
  }

  void onLoad() async {
    // await delay(const Duration(milliseconds: 500));
    final randomId = getRandomString(10);

    final expiry = DateTime.now()
        .add(const Duration(seconds: 60))
        .toUtc()
        .millisecondsSinceEpoch;

    final url =
        'https://citizenwallet.xyz?id=$randomId&account=${widget.account}&alias=${widget.alias}&exp=$expiry';

    final signature = widget.walletLogic.signMessage(url);

    await _logic
        .openApp('$url&signature=$signature'); // HARD CODE YOUR APP URL HERE

    handleDismiss();
  }

  void handleDismiss() {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomScrollView(
                      controller: ModalScrollController.of(context),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverFillRemaining(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(
                                color: ThemeColors.subtle.resolveFrom(context),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                'Launching app...',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.normal,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
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
      ),
    );
  }
}
