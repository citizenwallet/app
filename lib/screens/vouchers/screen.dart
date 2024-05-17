import 'package:citizenwallet/modals/wallet/voucher.dart';
import 'package:citizenwallet/modals/wallet/voucher_view.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/screens/vouchers/voucher_row.dart';
import 'package:citizenwallet/widgets/vouchers/amount_input_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VouchersScreen extends StatefulWidget {
  //final String title = 'Vouchers';

  const VouchersScreen({super.key});

  @override
  VouchersScreenState createState() => VouchersScreenState();
}

class VouchersScreenState extends State<VouchersScreen> {
  late VoucherLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = VoucherLogic(context);

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

    _logic.dispose();

    super.dispose();
  }

  void onLoad() async {
    await _logic.fetchVouchers();
  }

  void handleDismiss() {
    GoRouter.of(context).pop();
  }

  void handleMore(
    String address,
    String amount,
    bool isRedeemed,
  ) async {
    _logic.pause();

    final wallet = context.read<WalletState>().wallet;

    final option = await showCupertinoModalPopup<String?>(
        context: context,
        builder: (BuildContext dialogContext) {
          return CupertinoActionSheet(
            actions: [
              if (!isRedeemed)
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('share');
                  },
                  child: Text(AppLocalizations.of(context)!.share),
                ),
              if (!isRedeemed)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('return');
                  },
                  child: Text(AppLocalizations.of(context)!.returnFunds),
                ),
              if (isRedeemed)
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('delete');
                  },
                  child: Text(AppLocalizations.of(context)!.delete),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          );
        });

    if (option == 'share') {
      await CupertinoScaffold.showCupertinoModalBottomSheet<void>(
        context: context,
        expand: true,
        useRootNavigator: true,
        builder: (modalContext) => VoucherViewModal(
          address: address,
        ),
      );
    }

    if (option == 'return') {
      final confirm = await showCupertinoModalPopup<bool?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: AppLocalizations.of(context)!.returnVoucher,
          details: [
            '${(double.tryParse(amount) ?? 0.0).toStringAsFixed(2)} ${wallet?.symbol ?? ''} ${AppLocalizations.of(context)!.returnVoucherMsg}',
          ],
          confirmText: AppLocalizations.of(context)!.returnText,
        ),
      );

      if (confirm == true) await _logic.returnVoucher(address);
    }

    if (option == 'delete') {
      final confirm = await showCupertinoModalPopup<bool?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: AppLocalizations.of(context)!.deleteVoucher,
          details: [
            AppLocalizations.of(context)!.deleteVoucherMsg,
          ],
          confirmText: AppLocalizations.of(context)!.delete,
        ),
      );

      if (confirm == true) await _logic.deleteVoucher(address);
    }

    _logic.resume(address: address);
  }

  void handleCreateVoucher() async {
    HapticFeedback.heavyImpact();

    final wallet = context.read<WalletState>().wallet;
    if (wallet == null) {
      return;
    }

    final amount = await showCupertinoModalPopup<String?>(
      context: context,
      barrierDismissible: true,
      builder: (modalContext) => AmountInputModal(
        title: AppLocalizations.of(context)!.voucherAmount,
        placeholder: AppLocalizations.of(context)!.enteramount,
        symbol: wallet.symbol,
      ),
    );

    if (amount == null) {
      return;
    }

    await showCupertinoModalBottomSheet<bool?>(
      context: context,
      expand: true,
      topRadius: const Radius.circular(40),
      builder: (_) => VoucherModal(
        amount: amount,
        symbol: wallet.symbol,
      ),
    );

    onLoad();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final safeBottomPadding = MediaQuery.of(context).padding.bottom;

    final config = context.select((WalletState state) => state.config);

    final ready = context.select((WalletState state) => state.ready);

    final vouchers = selectVouchers(context.watch<VoucherState>());

    final loading = context.select((VoucherState state) => state.loading);

    final returnLoading =
        context.select((VoucherState state) => state.returnLoading);

    return CupertinoScaffold(
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: SafeArea(
            bottom: false,
            minimum: const EdgeInsets.only(left: 10, right: 10),
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  showBackButton: true,
                  title: AppLocalizations.of(context)!.vouchers,
                  actionButton: returnLoading
                      ? CupertinoActivityIndicator(
                          color: ThemeColors.subtle.resolveFrom(context),
                        )
                      : null,
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
                          if (vouchers.isEmpty && !loading)
                            SliverFillRemaining(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/voucher.svg',
                                    semanticsLabel:
                                        AppLocalizations.of(context)!
                                            .vouchericon,
                                    height: 200,
                                    width: 200,
                                  ),
                                  const SizedBox(height: 40),
                                  Text(
                                    AppLocalizations.of(context)!.vouchersMsg,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.normal,
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (vouchers.isNotEmpty)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                childCount: vouchers.length,
                                (context, index) {
                                  final voucher = vouchers[index];

                                  return Padding(
                                    key: Key(voucher.id),
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 10, 10, 10),
                                    child: VoucherRow(
                                      voucher: voucher,
                                      logic: _logic,
                                      logo: config?.community.logo,
                                      onTap: returnLoading ? null : handleMore,
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (vouchers.isNotEmpty)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 120),
                            ),
                        ],
                      ),
                      if (ready)
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
                              padding: EdgeInsets.fromLTRB(
                                  0, 10, 0, safeBottomPadding),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Button(
                                    text: AppLocalizations.of(context)!
                                        .createVoucher,
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
      ),
    );
  }
}
