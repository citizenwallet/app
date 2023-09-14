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
import 'package:citizenwallet/modals/vouchers/voucher_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class VouchersModal extends StatefulWidget {
  final String title = 'Vouchers';

  const VouchersModal({Key? key}) : super(key: key);

  @override
  VouchersModalState createState() => VouchersModalState();
}

class VouchersModalState extends State<VouchersModal> {
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
                  child: const Text('Share'),
                ),
              if (!isRedeemed)
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('return');
                  },
                  child: const Text('Return Funds'),
                ),
              if (isRedeemed)
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop('delete');
                  },
                  child: const Text('Delete'),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
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
          title: 'Return Voucher',
          details: [
            '${(double.tryParse(amount) ?? 0.0).toStringAsFixed(2)} ${wallet?.symbol ?? ''} will be returned to your wallet.',
          ],
          confirmText: 'Return',
        ),
      );

      if (confirm == true) await _logic.returnVoucher(address);
    }

    if (option == 'delete') {
      final confirm = await showCupertinoModalPopup<bool?>(
        context: context,
        barrierDismissible: true,
        builder: (modalContext) => ConfirmModal(
          title: 'Delete Voucher',
          details: [
            'This will remove the voucher from the list.',
          ],
          confirmText: 'Delete',
        ),
      );

      if (confirm == true) await _logic.deleteVoucher(address);
    }

    _logic.resume();
  }

  void handleCreateVoucher() {
    HapticFeedback.heavyImpact();

    // _logic.createMultipleVouchers(
    //   quantity: 20,
    //   balance: '1.0',
    //   symbol: 'RGN',
    // );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final config = context.select((WalletState state) => state.config);

    final vouchers = context.select(selectVouchers);

    final loading = context.select((VoucherState state) => state.loading);

    final returnLoading =
        context.select((VoucherState state) => state.returnLoading);

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
                actionButton: returnLoading
                    ? CupertinoActivityIndicator(
                        color: ThemeColors.subtle.resolveFrom(context),
                      )
                    : CupertinoButton(
                        padding: const EdgeInsets.all(5),
                        onPressed: handleDismiss,
                        child: Icon(
                          CupertinoIcons.xmark,
                          color: ThemeColors.touchable.resolveFrom(context),
                        ),
                      ),
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
                                  semanticsLabel: 'voucher icon',
                                  height: 200,
                                  width: 200,
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  'Your vouchers will appear here',
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
                                  key: Key(voucher.address),
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                      ],
                    ),
                    // Positioned(
                    //   bottom: 0,
                    //   width: width,
                    //   child: BlurryChild(
                    //     child: Container(
                    //       decoration: BoxDecoration(
                    //         border: Border(
                    //           top: BorderSide(
                    //             color: ThemeColors.subtle.resolveFrom(context),
                    //           ),
                    //         ),
                    //       ),
                    //       padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    //       child: Column(
                    //         children: [
                    //           const SizedBox(height: 10),
                    //           Button(
                    //             text: 'Create Voucher',
                    //             onPressed: handleCreateVoucher,
                    //             minWidth: 200,
                    //             maxWidth: 200,
                    //           ),
                    //           const SizedBox(height: 10),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
