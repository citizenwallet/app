import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/utils/strings.dart';

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

class VoucherModalState extends State<VoucherModal>
    with SingleTickerProviderStateMixin {
  late VoucherLogic _logic;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      value: 1,
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logic = VoucherLogic(context);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);

    _logic.dispose();

    super.dispose();
  }

  void onLoad() async {}

  void handleDismiss(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();

    // inform the previous modal to close if the voucher is ready to share
    final shareReady = context.read<VoucherState>().shareReady;

    GoRouter.of(context).pop(shareReady);
  }

  void handleCreateVoucher() async {
    await _logic.createVoucher(
      balance: widget.amount,
      symbol: widget.symbol!,
    );

    await _controller.animateTo(0);

    _logic.shareReady();
  }

  void handleShareVoucher(
    BuildContext context,
    String address,
    String balance,
    String symbol,
    String link,
  ) {
    final box = context.findRenderObject() as RenderBox?;

    _logic.shareVoucher(
      address,
      balance,
      symbol,
      link,
      box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void handleShareLater() {
    GoRouter.of(context).pop(true);
  }

  void handleCopy(String link) {
    _logic.copyVoucher(link);
  }

  @override
  Widget build(BuildContext context) {
    const voucherInfoHeight = 400.0;
    final height = MediaQuery.of(context).size.height;
    final reservedHeight = ((height - voucherInfoHeight) * -1) + 400;

    final width = MediaQuery.of(context).size.width;

    final createdVoucher =
        context.select((VoucherState state) => state.createdVoucher);
    final creationState =
        context.select((VoucherState state) => state.creationState);
    final createLoading =
        context.select((VoucherState state) => state.createLoading);

    final shareLink = context.select((VoucherState state) => state.shareLink);
    final shareReady = context.select((VoucherState state) => state.shareReady);

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
                              child: shareReady
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: ThemeColors.white
                                            .resolveFrom(context),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: QR(
                                        data: shareLink,
                                        size: 280,
                                      ),
                                    )
                                  : Lottie.asset(
                                      'assets/lottie/gift-voucher.json',
                                      controller: _controller,
                                      height: 300,
                                      width: 300,
                                      animate: false,
                                      repeat: false,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
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
                              'Create a voucher which anyone can redeem for the amount shown above.',
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (creationState != VoucherCreationState.none)
                            (creationState == VoucherCreationState.created)
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Chip(
                                        onTap: () => handleCopy(shareLink),
                                        formatLongText(shareLink, length: 12),
                                        color: ThemeColors.subtleEmphasis
                                            .resolveFrom(context),
                                        textColor: ThemeColors.touchable
                                            .resolveFrom(context),
                                        suffix: Icon(
                                          CupertinoIcons.square_on_square,
                                          size: 14,
                                          color: ThemeColors.touchable
                                              .resolveFrom(context),
                                        ),
                                        borderRadius: 15,
                                        maxWidth: 300,
                                      ),
                                    ],
                                  )
                                : Text(
                                    creationState.description,
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
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
                            children: creationState ==
                                        VoucherCreationState.created &&
                                    createdVoucher != null &&
                                    !createLoading
                                ? [
                                    const SizedBox(height: 10),
                                    Button(
                                      text: 'Share',
                                      suffix: Row(
                                        children: [
                                          const SizedBox(width: 10),
                                          Icon(
                                            CupertinoIcons.share,
                                            size: 18,
                                            color: ThemeColors.black
                                                .resolveFrom(context),
                                          ),
                                        ],
                                      ),
                                      onPressed: () => handleShareVoucher(
                                        context,
                                        createdVoucher.address,
                                        createdVoucher.balance,
                                        widget.symbol!,
                                        shareLink,
                                      ),
                                      minWidth: 200,
                                      maxWidth: 200,
                                    ),
                                    const SizedBox(height: 10),
                                    CupertinoButton(
                                      onPressed: handleShareLater,
                                      child: Text(
                                        'Share later',
                                        style: TextStyle(
                                          color: ThemeColors.text
                                              .resolveFrom(context),
                                          fontSize: 18,
                                          fontWeight: FontWeight.normal,
                                          decoration: TextDecoration.underline,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ]
                                : [
                                    const SizedBox(height: 10),
                                    createLoading
                                        ? SizedBox(
                                            height: 44,
                                            child: CupertinoActivityIndicator(
                                              color: ThemeColors.subtle
                                                  .resolveFrom(context),
                                            ),
                                          )
                                        : Button(
                                            text: 'Create',
                                            onPressed: handleCreateVoucher,
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
