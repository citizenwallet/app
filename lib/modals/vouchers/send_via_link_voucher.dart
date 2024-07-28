import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:citizenwallet/widgets/wallet/coin_spinner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:lottie/lottie.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/utils/strings.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

const List<Color> _kDefaultRainbowColors = [Color(0xFF9463D2)];

class SendViaLinkVoucherModal extends StatefulWidget {
  final String amount;
  final String? symbol;
  final String? name;

  const SendViaLinkVoucherModal({
    super.key,
    required this.amount,
    this.symbol,
    this.name,
  });

  @override
  SendViaLinkVoucherModalState createState() => SendViaLinkVoucherModalState();
}

class SendViaLinkVoucherModalState extends State<SendViaLinkVoucherModal>
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // initial requests go here

      await _logic.createVoucher(
        name: widget.name,
        balance: widget.amount,
        symbol: widget.symbol!,
      );

      // await _controller.animateTo(0);

      _logic.shareReady();
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
      name: widget.name,
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
    GoRouter.of(context).push('/wallet/:address');
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

    final size = height > width ? width : height;

    final createdVoucher = context.watch<VoucherState>().createdVoucher;
    final creationState =
        context.select((VoucherState state) => state.creationState);
    final createLoading =
        context.select((VoucherState state) => state.createLoading);

    final shareLink = context.select((VoucherState state) => state.shareLink);
    final shareReady = context.select((VoucherState state) => state.shareReady);

    String formattedDateTime =
        DateFormat('MMM d, yyyy - HH:mm').format(DateTime.now());

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.background.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  color: ThemeColors.background,
                  titleWidget: Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(5),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.arrow_left,
                          color: ThemeColors.touchable.resolveFrom(context),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context)!.send,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8F899C),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                            height: size * 0.7,
                            width: size * 0.7,
                            child: Center(
                                child: shareReady
                                    ? Container(
                                        decoration: BoxDecoration(
                                            color: ThemeColors.white
                                                .resolveFrom(context),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                                color: ThemeColors
                                                    .surfacePrimary
                                                    .resolveFrom(context),
                                                width: 2)),
                                        child: QR(
                                          data: shareLink,
                                          size: size * 0.7,
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                            color: ThemeColors.uiBackground
                                                .resolveFrom(context),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            border: Border.all(
                                                color: ThemeColors
                                                    .surfacePrimary
                                                    .resolveFrom(context),
                                                width: 2)),
                                        child: Transform.scale(
                                          scale: 0.3,
                                          child: const LoadingIndicator(
                                            indicatorType:
                                                Indicator.circleStrokeSpin,
                                            colors: _kDefaultRainbowColors,
                                            strokeWidth: 10.0,
                                            pathBackgroundColor:
                                                Color.fromRGBO(81, 66, 66, 0),
                                          ),
                                        ),
                                      )),
                          ),
                          const SizedBox(height: 30),
                          if (creationState == VoucherCreationState.created &&
                              createdVoucher != null &&
                              !createLoading)
                            Text(
                              "Voucher created",
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 30),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // CoinSpinner(
                                  //     key: Key('${wallet?.alias}-spinner'),
                                  //     size: coinSize,
                                  //     logo: wallet!.currencyLogo),
                                  // const SizedBox(width: 16.77),
                                  Text(
                                    widget.amount,
                                    style: const TextStyle(
                                      color: Color(0xFF1E2122),
                                      fontSize: 41.94,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 0.5,
                                      letterSpacing: -0.11,
                                    ),
                                  ),
                                  const SizedBox(width: 16.77),
                                  Text(
                                    widget.symbol!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 52, 52, 52),
                                      fontSize: 17,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      height: 0.08,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (creationState == VoucherCreationState.created &&
                              createdVoucher != null &&
                              !createLoading)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(CupertinoIcons.clock,
                                      color: ThemeColors.surfacePrimary
                                          .resolveFrom(context),
                                      size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedDateTime,
                                    style: TextStyle(
                                        color: ThemeColors.subtleSolid
                                            .resolveFrom(context),
                                        fontSize: 16,
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 30),
                          if (creationState == VoucherCreationState.none)
                            Text(
                              AppLocalizations.of(context)!.createVoucherText,
                              style: TextStyle(
                                color: ThemeColors.text.resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          if (creationState != VoucherCreationState.none)
                            (creationState == VoucherCreationState.created)
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Chip(
                                      //   onTap: () => handleCopy(shareLink),
                                      //   formatLongText(shareLink, length: 12),
                                      //   color: ThemeColors.subtleEmphasis
                                      //       .resolveFrom(context),
                                      //   textColor: ThemeColors.touchable
                                      //       .resolveFrom(context),
                                      //   suffix: Icon(
                                      //     CupertinoIcons.square_on_square,
                                      //     size: 14,
                                      //     color: ThemeColors.touchable
                                      //         .resolveFrom(context),
                                      //   ),
                                      //   maxWidth: 300,
                                      // ),
                                    ],
                                  )
                                : Text(
                                    creationState.description,
                                    style: TextStyle(
                                      color: ThemeColors.success
                                          .resolveFrom(context),
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
                          decoration: const BoxDecoration(
                            border: Border(
                                // top: BorderSide(
                                //   color: ThemeColors.subtle.resolveFrom(context),
                                // ),
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
                                      text: 'Share Link',
                                      suffix: Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.share,
                                            size: 18,
                                            color: ThemeColors.white
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
                                      minWidth: 100,
                                      maxWidth: 150,
                                    ),
                                    const SizedBox(height: 10),
                                    CupertinoButton(
                                      onPressed: handleShareLater,
                                      child: Text(
                                        'Cancel & Refund',
                                        style: TextStyle(
                                          color: ThemeColors.surfacePrimary
                                              .resolveFrom(context),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          //decoration: TextDecoration.underline,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Button(
                                      text: 'Done',
                                      onPressed: handleShareLater,
                                      minWidth: 100,
                                      maxWidth: width / 3 * 2,
                                    )
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
                                            text: AppLocalizations.of(context)!
                                                .create,
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
