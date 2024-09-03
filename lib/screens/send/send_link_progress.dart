import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/loaders/progress_circle.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendLinkProgress extends StatefulWidget {
  final VoucherLogic voucherLogic;

  const SendLinkProgress({
    super.key,
    required this.voucherLogic,
  });

  @override
  State<SendLinkProgress> createState() => _SendLinkProgressState();
}

class _SendLinkProgressState extends State<SendLinkProgress> {
  VoucherCreationState _previousState = VoucherCreationState.none;

  bool _isClosing = false;
  bool _isReadyUpdating = false;
  bool _isReady = false;

  void handleDone(BuildContext context, {String? address}) {
    if (!context.mounted) {
      return;
    }

    final navigator = GoRouter.of(context);

    navigator.pop((
      sent: true,
      address: address,
    ));
  }

  void handleRetry(BuildContext context) {
    final navigator = GoRouter.of(context);

    navigator.pop();
  }

  void handleStartCloseScreenTimer(BuildContext context) {
    if (_isClosing) {
      return;
    }

    _isClosing = true;

    Future.delayed(const Duration(seconds: 5), () {
      handleDone(context);
    });
  }

  void handleReady() async {
    if (_isReady || _isReadyUpdating) {
      return;
    }

    _isReadyUpdating = true;

    await delay(const Duration(milliseconds: 500));

    setState(() {
      _isReady = true;
    });
  }

  void handleShareVoucher(
    BuildContext context,
    String address,
    String balance,
    String symbol,
    String link,
  ) {
    final box = context.findRenderObject() as RenderBox?;

    widget.voucherLogic.shareVoucher(
      address,
      balance,
      symbol,
      link,
      box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  void handleRefund(BuildContext context, String address, String amount,
      String symbol) async {
    final confirm = await showCupertinoModalPopup<bool?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => ConfirmModal(
        title: AppLocalizations.of(modalContext)!.returnVoucher,
        details: [
          '${(double.tryParse(amount) ?? 0.0).toStringAsFixed(2)} $symbol ${AppLocalizations.of(context)!.returnVoucherMsg}',
        ],
        confirmText: AppLocalizations.of(context)!.returnText,
      ),
    );

    if (confirm == true) {
      widget.voucherLogic.returnVoucher(address);

      if (!context.mounted) {
        return;
      }

      final navigator = GoRouter.of(context);

      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : height;

    final wallet = context.select((WalletState state) => state.wallet);

    if (wallet == null) {
      return const SizedBox();
    }

    final date = DateFormat.yMMMd().add_Hm().format(DateTime.now());

    final createdVoucher = context.watch<VoucherState>().createdVoucher;

    final formattedAmount = createdVoucher != null
        ? formatAmount(
            double.parse(fromDoubleUnit(
              createdVoucher.balance,
              decimals: wallet.decimalDigits,
            )),
            decimalDigits: 2,
          )
        : '';

    final creationState =
        context.select((VoucherState state) => state.creationState);

    if (_previousState == VoucherCreationState.creating &&
        creationState == VoucherCreationState.funding) {
      handleReady();
    }

    _previousState = creationState;

    final isCreating = creationState == VoucherCreationState.creating ||
        creationState == VoucherCreationState.none;
    final createError =
        context.select((VoucherState state) => state.createError);

    final shareLink = context.select((VoucherState state) => state.shareLink);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum:
              const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomScrollView(
                      scrollBehavior: const CupertinoScrollBehavior(),
                      slivers: [
                        SliverFillRemaining(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    !_isReady
                                        ? Container(
                                            height: size * 0.8,
                                            width: size * 0.8,
                                            decoration: BoxDecoration(
                                              color: isCreating
                                                  ? Theme.of(context)
                                                      .colors
                                                      .subtleEmphasis
                                                      .resolveFrom(context)
                                                  : Theme.of(context)
                                                      .colors
                                                      .white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      size * 0.1),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colors
                                                    .primary
                                                    .resolveFrom(context),
                                                width: 1,
                                              ),
                                            ),
                                            child: ProgressCircle(
                                              progress: switch (creationState) {
                                                VoucherCreationState.creating =>
                                                  0.5,
                                                VoucherCreationState.funding =>
                                                  1,
                                                VoucherCreationState.created =>
                                                  1,
                                                _ => 0,
                                              },
                                              size: 100,
                                              color: Theme.of(context)
                                                  .colors
                                                  .primary
                                                  .resolveFrom(context),
                                              trackColor: createError
                                                  ? Theme.of(context)
                                                      .colors
                                                      .danger
                                                      .resolveFrom(context)
                                                      .withOpacity(0.25)
                                                  : null,
                                              successChild: Icon(
                                                CupertinoIcons.checkmark,
                                                size: 60,
                                                color: Theme.of(context)
                                                    .colors
                                                    .success
                                                    .resolveFrom(context),
                                              ),
                                            ),
                                          )
                                        : AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            opacity: _isReady && !createError
                                                ? 1
                                                : 0,
                                            child: QR(
                                              data: shareLink,
                                              size: size * 0.8,
                                              padding: const EdgeInsets.all(20),
                                            ),
                                          ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isCreating
                                      ? AppLocalizations.of(context)!
                                          .voucherCreating
                                      : !createError
                                          ? switch (creationState) {
                                              VoucherCreationState.creating =>
                                                AppLocalizations.of(context)!
                                                    .voucherCreating,
                                              VoucherCreationState.funding =>
                                                AppLocalizations.of(context)!
                                                    .voucherFunding,
                                              _ => AppLocalizations.of(context)!
                                                  .voucherCreated,
                                            }
                                          : AppLocalizations.of(context)!
                                              .voucherCreateFailed,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .text
                                        .resolveFrom(context),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                                if (createdVoucher != null)
                                  const SizedBox(height: 20),
                                if (createdVoucher != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CoinLogo(
                                        size: 60,
                                        logo: wallet.currencyLogo,
                                      ),
                                      const SizedBox(width: 20),
                                      Text(
                                        formattedAmount,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colors
                                              .text
                                              .resolveFrom(context),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          0,
                                          0,
                                          0,
                                          0,
                                        ),
                                        child: Text(
                                          wallet.symbol,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colors
                                                .text
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!isCreating && !createError)
                                  const SizedBox(height: 20),
                                if (!isCreating && !createError)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.time,
                                        color: Theme.of(context)
                                            .colors
                                            .subtleSolid
                                            .resolveFrom(context),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        date,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colors
                                              .subtleSolid
                                              .resolveFrom(context),
                                          fontWeight: FontWeight.normal,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!isCreating && !createError)
                                  const SizedBox(height: 20),
                                if (!isCreating && !createError)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Button(
                                        text:
                                            AppLocalizations.of(context)!.share,
                                        labelColor: Theme.of(context)
                                            .colors
                                            .white
                                            .resolveFrom(context),
                                        suffix: const Padding(
                                          padding: EdgeInsets.only(right: 10),
                                          child: Icon(
                                            CupertinoIcons.share_up,
                                          ),
                                        ),
                                        onPressed: () => handleShareVoucher(
                                          context,
                                          createdVoucher!.address,
                                          createdVoucher.balance,
                                          wallet.symbol,
                                          shareLink,
                                        ),
                                        minWidth: 160,
                                        maxWidth: 160,
                                      ),
                                    ],
                                  ),
                                if (!isCreating && !createError)
                                  const SizedBox(height: 10),
                                if (!isCreating && !createError)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Button(
                                        text: AppLocalizations.of(context)!
                                            .cancelRefund,
                                        color: Theme.of(context)
                                            .colors
                                            .transparent
                                            .resolveFrom(context),
                                        labelColor: Theme.of(context)
                                            .colors
                                            .primary
                                            .resolveFrom(context),
                                        onPressed: () => handleRefund(
                                          context,
                                          createdVoucher!.address,
                                          createdVoucher.balance,
                                          wallet.symbol,
                                        ),
                                        minWidth: 160,
                                        maxWidth: 160,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 80),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isCreating && !createError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Button(
                      text: AppLocalizations.of(context)!.dismiss,
                      labelColor:
                          Theme.of(context).colors.white.resolveFrom(context),
                      onPressed: () =>
                          handleDone(context, address: createdVoucher!.address),
                      minWidth: 200,
                      maxWidth: width - 60,
                    ),
                  ],
                ),
              if (!isCreating && createError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Button(
                      text: AppLocalizations.of(context)!.retry,
                      labelColor:
                          Theme.of(context).colors.white.resolveFrom(context),
                      onPressed: () => handleRetry(context),
                      minWidth: 200,
                      maxWidth: width - 60,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
