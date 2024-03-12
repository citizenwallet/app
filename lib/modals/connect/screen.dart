import 'package:citizenwallet/modals/wallet/voucher_view.dart';
import 'package:citizenwallet/state/connect/logic.dart';
import 'package:citizenwallet/state/connect/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/modals/vouchers/voucher_row.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/scanner/scanner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class ConnectModal extends StatefulWidget {
  final String title = 'Connect';
  final String account;
  final String address;
  final EthPrivateKey credentials;

  const ConnectModal({
    super.key,
    required this.account,
    required this.address,
    required this.credentials,
  });

  @override
  ConnectModalState createState() => ConnectModalState();
}

class ConnectModalState extends State<ConnectModal> {
  late ConnectLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = ConnectLogic(
      context,
      widget.account,
      widget.address,
    );

    WidgetsBinding.instance.addObserver(_logic);

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);

    super.dispose();
  }

  void onLoad() async {
    await _logic.init();
  }

  void handleDismiss() {
    GoRouter.of(context).pop();
  }

  void handleConnect() async {
    HapticFeedback.heavyImpact();

    // await _logic.connect();

    // await _logic.sign('0x123');

    // _logic.createMultipleVouchers(
    //   quantity: 20,
    //   balance: '1.0',
    //   symbol: 'RGN',
    // );
  }

  void handleScan(String data) async {
    print(data);
    await _logic.connect(data);
  }

  void handleAccept(AuthMetadata metadata) async {
    HapticFeedback.heavyImpact();

    await _logic.accept(metadata, widget.credentials);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final ready = context.select((ConnectState state) => state.ready);
    final metadata = context.select((ConnectState state) => state.metadata);

    final vouchers = [];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: widget.title,
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomScrollView(
                      controller: ModalScrollController.of(context),
                      scrollBehavior: const CupertinoScrollBehavior(),
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (ready)
                          SliverFillRemaining(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: metadata == null
                                  ? [
                                      Scanner(
                                        height: 200,
                                        width: 200,
                                        onScan: handleScan,
                                      ),
                                      const SizedBox(height: 40),
                                    ]
                                  : [
                                      Text(metadata.name),
                                      const SizedBox(height: 10),
                                      ProfileCircle(
                                        imageUrl: metadata.icons.first,
                                      ),
                                      const SizedBox(height: 10),
                                      Button(
                                        text: 'Accept',
                                        onPressed: () => handleAccept(metadata),
                                        minWidth: 200,
                                        maxWidth: 200,
                                      ),
                                    ],
                            ),
                          ),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      width: width,
                      child: BlurryChild(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: ThemeColors.subtle.resolveFrom(context),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              Button(
                                text: 'Connect',
                                onPressed: handleConnect,
                                minWidth: 200,
                                maxWidth: 200,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
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
