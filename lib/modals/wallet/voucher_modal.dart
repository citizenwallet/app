import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class VoucherModal extends StatefulWidget {
  final String amount;
  final String? symbol;

  const VoucherModal({
    Key? key,
    required this.amount,
    this.symbol,
  }) : super(key: key);

  @override
  VoucherModalState createState() => VoucherModalState();
}

class VoucherModalState extends State<VoucherModal> {
  late VoucherLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = VoucherLogic(context);

    WidgetsBinding.instance?.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  void onLoad() async {}

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    GoRouter.of(context).pop();
  }

  void handleCreateVoucher() {
    _logic.createVoucher(balance: widget.amount);
  }

  void handleShareVoucher() {
    print('share voucher');
  }

  @override
  Widget build(BuildContext context) {
    final createdVoucher =
        context.select((VoucherState state) => state.createdVoucher);
    final creationState =
        context.select((VoucherState state) => state.creationState);
    final createLoading =
        context.select((VoucherState state) => state.createLoading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  title: 'Create Voucher',
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: ListView(
                        controller: ModalScrollController.of(context),
                        physics: const ScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        scrollDirection: Axis.vertical,
                        children: [
                          SizedBox(
                            height: 300,
                            width: 300,
                            child: Center(
                              child: Lottie.asset(
                                'assets/lottie/gift-voucher.json',
                                height: 300,
                                width: 300,
                                animate: true,
                                repeat: false,
                                // controller: _controller,
                              ),
                            ),
                          ),
                          Text(
                            widget.symbol != null
                                ? '${widget.symbol} ${widget.amount}'
                                : widget.amount,
                            style: TextStyle(
                              color: ThemeColors.text.resolveFrom(context),
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          if (creationState == VoucherCreationState.none)
                            Text(
                              'Send this voucher to anyone and they can redeem it for the amount shown above.',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (creationState != VoucherCreationState.none)
                            Text(
                              creationState.description,
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                    if (creationState != VoucherCreationState.created &&
                        createdVoucher == null)
                      Positioned(
                        bottom: 40,
                        child: Column(
                          children: [
                            createLoading
                                ? CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
                                  )
                                : Button(
                                    text: 'Create',
                                    onPressed: handleCreateVoucher,
                                    minWidth: 200,
                                    maxWidth: 200,
                                  ),
                          ],
                        ),
                      ),
                    if (creationState == VoucherCreationState.created &&
                        createdVoucher != null &&
                        !createLoading)
                      Positioned(
                        bottom: 40,
                        child: Column(
                          children: [
                            Button(
                              text: 'Share',
                              suffix: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Icon(
                                    CupertinoIcons.share,
                                    size: 18,
                                    color:
                                        ThemeColors.black.resolveFrom(context),
                                  ),
                                ],
                              ),
                              onPressed: handleShareVoucher,
                              minWidth: 200,
                              maxWidth: 200,
                            ),
                          ],
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
