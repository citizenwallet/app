import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/utils/strings.dart';

class VoucherViewModal extends StatefulWidget {
  final String address;

  const VoucherViewModal({
    Key? key,
    required this.address,
  }) : super(key: key);

  @override
  VoucherViewModalState createState() => VoucherViewModalState();
}

class VoucherViewModalState extends State<VoucherViewModal>
    with SingleTickerProviderStateMixin {
  late VoucherLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = VoucherLogic(context);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.clearOpenVoucher();

    WidgetsBinding.instance.removeObserver(_logic);

    _logic.dispose();

    super.dispose();
  }

  void onLoad() async {
    _logic.openVoucher(widget.address);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
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

  void handleCopy(String link) {
    _logic.copyVoucher(link);
  }

  @override
  Widget build(BuildContext context) {
    const voucherInfoHeight = 400.0;
    final height = MediaQuery.of(context).size.height;
    final reservedHeight = ((height - voucherInfoHeight) * -1) + 400;

    final wallet = context.select((WalletState state) => state.wallet);

    final width = MediaQuery.of(context).size.width;
    final size = height > width ? width : height;

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
                  title: '',
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
                          Text(
                            voucher?.name ?? 'Voucher',
                            style: TextStyle(
                              color: ThemeColors.text.resolveFrom(context),
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            height: size * 0.8,
                            width: size * 0.8,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: size * 0.8,
                                width: size * 0.8,
                                decoration: BoxDecoration(
                                  color: viewLoading || voucher == null
                                      ? ThemeColors.uiBackgroundAlt
                                          .resolveFrom(context)
                                      : ThemeColors.white.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: viewLoading || voucher == null
                                    ? CupertinoActivityIndicator(
                                        color: ThemeColors.subtle
                                            .resolveFrom(context))
                                    : QR(
                                        data: viewingVoucherLink!,
                                        size: size * 0.8,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (!viewLoading &&
                              voucher != null &&
                              viewingVoucherLink != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Chip(
                                  onTap: () => handleCopy(viewingVoucherLink),
                                  formatLongText(viewingVoucherLink,
                                      length: 12),
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
                                  maxWidth: 300,
                                ),
                              ],
                            ),
                          SizedBox(
                            height: reservedHeight > 0 ? reservedHeight : 0,
                          ),
                        ],
                      ),
                    ),
                    if (!viewLoading &&
                        voucher != null &&
                        viewingVoucherLink != null)
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
                                    voucher.address,
                                    voucher.balance,
                                    wallet?.symbol ?? '',
                                    viewingVoucherLink,
                                  ),
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
