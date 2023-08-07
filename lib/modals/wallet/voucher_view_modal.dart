import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 300,
                                width: 300,
                                decoration: BoxDecoration(
                                  color: viewLoading || voucher == null
                                      ? ThemeColors.uiBackgroundAlt
                                          .resolveFrom(context)
                                      : ThemeColors.white.resolveFrom(context),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.all(10),
                                child: viewLoading || voucher == null
                                    ? CupertinoActivityIndicator(
                                        color: ThemeColors.subtle
                                            .resolveFrom(context))
                                    : PrettyQr(
                                        data: viewingVoucherLink!,
                                        size: 280,
                                        roundEdges: false,
                                      ),
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
                                  borderRadius: 15,
                                  maxWidth: 300,
                                ),
                              ],
                            ),
                          SizedBox(
                              height: reservedHeight > 0 ? reservedHeight : 0),
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
