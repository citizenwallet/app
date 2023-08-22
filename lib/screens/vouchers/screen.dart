import 'package:citizenwallet/modals/wallet/voucher_view_modal.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/selectors.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/confirm_modal.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/screens/vouchers/voucher_row.dart';
import 'package:citizenwallet/widgets/persistent_header_delegate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class VouchersScreen extends StatefulWidget {
  final String title = 'Vouchers';

  const VouchersScreen({Key? key}) : super(key: key);

  @override
  VouchersScreenState createState() => VouchersScreenState();
}

class VouchersScreenState extends State<VouchersScreen> {
  final ScrollController _scrollController = ScrollController();

  late VoucherLogic _logic;
  late WalletLogic _walletLogic;

  @override
  void initState() {
    super.initState();

    _logic = VoucherLogic(context);
    _walletLogic = WalletLogic(context);

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

    // _scrollController.animateTo(
    //   60,
    //   duration: const Duration(milliseconds: 250),
    //   curve: Curves.easeInOut,
    // );
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
            '${(double.tryParse(amount) ?? 0.0) / 1000} ${wallet?.symbol ?? ''} will be return to your wallet.',
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

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    final vouchers = context.select(selectVouchers);

    final loading = context.select((VoucherState state) => state.loading);

    final returnLoading =
        context.select((VoucherState state) => state.returnLoading);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            controller: _scrollController,
            scrollBehavior: const CupertinoScrollBehavior(),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                floating: false,
                delegate: PersistentHeaderDelegate(
                  expandedHeight: safePadding + 60,
                  minHeight: safePadding + 60,
                  builder: (context, shrink) => BlurryChild(
                    child: Container(
                      color: ThemeColors.transparent,
                    ),
                  ),
                ),
              ),
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
                          color: ThemeColors.text.resolveFrom(context),
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
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                        child: VoucherRow(
                          voucher: voucher,
                          logic: _logic,
                          onTap: returnLoading ? null : handleMore,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          SafeArea(
            child: Header(
              transparent: true,
              color: ThemeColors.transparent,
              title: widget.title,
              actionButton: returnLoading
                  ? CupertinoActivityIndicator(
                      color: ThemeColors.subtle.resolveFrom(context),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
