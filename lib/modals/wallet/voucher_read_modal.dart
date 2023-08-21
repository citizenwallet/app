import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class VoucherReadModal extends StatefulWidget {
  final String address;

  const VoucherReadModal({
    Key? key,
    required this.address,
  }) : super(key: key);

  @override
  VoucherReadModalState createState() => VoucherReadModalState();
}

class VoucherReadModalState extends State<VoucherReadModal>
    with SingleTickerProviderStateMixin {
  late VoucherLogic _logic;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      value: 0,
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logic = VoucherLogic(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.clearOpenVoucher();

    super.dispose();
  }

  void onLoad() async {
    await _logic.openVoucher(widget.address);

    _controller.animateTo(1);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleRedeem() {
    GoRouter.of(context).pop(widget.address);
  }

  @override
  Widget build(BuildContext context) {
    const voucherInfoHeight = 400.0;
    final height = MediaQuery.of(context).size.height;
    final reservedHeight = ((height - voucherInfoHeight) * -1) + 400;

    final width = MediaQuery.of(context).size.width;

    final voucher =
        context.select((VoucherState state) => state.viewingVoucher);
    final viewLoading =
        context.select((VoucherState state) => state.viewLoading);

    final viewingVoucherLink =
        context.select((VoucherState state) => state.viewingVoucherLink);

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
                  title: 'Voucher',
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
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            width: 300,
                            child: Center(
                              child: viewLoading || voucher == null
                                  ? CupertinoActivityIndicator(
                                      color: ThemeColors.subtle
                                          .resolveFrom(context))
                                  : Lottie.asset(
                                      'assets/lottie/gift-voucher.json',
                                      controller: _controller,
                                      height: 300,
                                      width: 300,
                                      animate: true,
                                      repeat: false,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            voucher?.name ?? '',
                            style: TextStyle(
                              color: ThemeColors.text.resolveFrom(context),
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          if (!viewLoading &&
                              voucher != null &&
                              viewingVoucherLink != null)
                            Text(
                              'Redeem this voucher to your account.',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          SizedBox(
                              height: reservedHeight > 0 ? reservedHeight : 0),
                        ],
                      ),
                    ),
                    if (voucher != null)
                      Positioned(
                        bottom: 0,
                        width: width,
                        child: BlurryChild(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color:
                                      ThemeColors.subtle.resolveFrom(context),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                if (!viewLoading)
                                  Button(
                                    text: 'Redeem',
                                    suffix: Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        Icon(
                                          CupertinoIcons.arrow_down_circle,
                                          size: 18,
                                          color: ThemeColors.black
                                              .resolveFrom(context),
                                        ),
                                      ],
                                    ),
                                    onPressed: handleRedeem,
                                    minWidth: 200,
                                    maxWidth: 200,
                                  ),
                                if (viewLoading)
                                  CupertinoActivityIndicator(
                                    color:
                                        ThemeColors.subtle.resolveFrom(context),
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
