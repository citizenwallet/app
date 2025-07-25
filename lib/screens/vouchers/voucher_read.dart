import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_badge.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class VoucherReadScreen extends StatefulWidget {
  final String address;
  final WalletLogic logic;

  const VoucherReadScreen({
    super.key,
    required this.address,
    required this.logic,
  });

  @override
  VoucherReadScreenState createState() => VoucherReadScreenState();
}

class VoucherReadScreenState extends State<VoucherReadScreen>
    with SingleTickerProviderStateMixin {
  late VoucherLogic _logic;
  late ProfilesLogic _profilesLogic;

  @override
  void initState() {
    super.initState();

    _logic = VoucherLogic(context);
    _profilesLogic = ProfilesLogic(context);

    WidgetsBinding.instance.addObserver(_logic);
    WidgetsBinding.instance.addObserver(_profilesLogic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    _logic.clearOpenVoucher();

    WidgetsBinding.instance.removeObserver(_logic);
    WidgetsBinding.instance.removeObserver(_profilesLogic);

    _logic.dispose();
    _profilesLogic.dispose();

    super.dispose();
  }

  void onLoad() async {
    final walletLogic = widget.logic;
    if (walletLogic.config != null &&
        walletLogic.credentials != null &&
        walletLogic.accountAddress != null) {
      _logic.setWalletState(
        walletLogic.config!,
        walletLogic.credentials!,
        walletLogic.accountAddress!,
      );
    }
    final voucher = await _logic.openVoucher(widget.address);

    if (voucher == null) {
      return;
    }

    _profilesLogic.loadProfile(voucher.creator);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleRedeem() async {
    final navigator = GoRouter.of(context);

    _logic.returnVoucher(
      widget.address,
      preSendingTransaction: widget.logic.preSendingTransaction,
      sendingTransaction: widget.logic.sendingTransaction,
    );

    await delay(const Duration(milliseconds: 1500));

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    const voucherInfoHeight = 400.0;
    final height = MediaQuery.of(context).size.height;
    final reservedHeight = ((height - voucherInfoHeight) * -1) + 400;

    final width = MediaQuery.of(context).size.width;

    final config = context.select((WalletState state) => state.config);

    final voucher =
        context.select((VoucherState state) => state.viewingVoucher);
    final viewLoading =
        context.select((VoucherState state) => state.viewLoading);
    final returnLoading =
        context.select((VoucherState state) => state.returnLoading);

    final viewingVoucherLink =
        context.select((VoucherState state) => state.viewingVoucherLink);

    final profiles = context.watch<ProfilesState>().profiles;

    final profile = profiles[voucher?.creator ?? ''];

    final emptyBalance = (double.tryParse(voucher?.balance ?? '0') ?? 0) <= 0;

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
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  showBackButton: true,
                  title: '',
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
                            voucher?.name ?? '',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colors
                                  .text
                                  .resolveFrom(context),
                              fontSize: 28,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 120,
                            width: 120,
                            child: Center(
                              child: viewLoading || voucher == null
                                  ? CupertinoActivityIndicator(
                                      color: Theme.of(context)
                                          .colors
                                          .subtle
                                          .resolveFrom(context))
                                  : CoinLogo(
                                      size: 100,
                                      logo: config?.community.logo,
                                    ),
                            ),
                          ),
                          if (profile != null) ...[
                            const SizedBox(height: 30),
                            Text(
                              AppLocalizations.of(context)!.createdBy,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .text
                                    .resolveFrom(context),
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ProfileBadge(
                              profile: profile.profile,
                              loading: profile.loading,
                              size: 120,
                            ),
                          ],
                          const SizedBox(height: 50),
                          if (!viewLoading &&
                              voucher != null &&
                              viewingVoucherLink != null)
                            Text(
                              emptyBalance
                                  ? AppLocalizations.of(context)!
                                      .emptyBalanceText1
                                  : AppLocalizations.of(context)!
                                      .emptyBalanceText2,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .text
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
                    if (voucher != null && !emptyBalance)
                      Positioned(
                        bottom: 0,
                        width: width,
                        child: BlurryChild(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Theme.of(context)
                                      .colors
                                      .subtle
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                if (!viewLoading && !returnLoading)
                                  Button(
                                    text: AppLocalizations.of(context)!.redeem,
                                    labelColor: Theme.of(context).colors.white,
                                    suffix: Row(
                                      children: [
                                        const SizedBox(width: 10),
                                        Icon(
                                          CupertinoIcons.arrow_down_circle,
                                          size: 18,
                                          color: Theme.of(context).colors.white,
                                        ),
                                      ],
                                    ),
                                    onPressed: handleRedeem,
                                    minWidth: 200,
                                    maxWidth: 200,
                                  ),
                                if (viewLoading || returnLoading)
                                  CupertinoActivityIndicator(
                                    color: Theme.of(context)
                                        .colors
                                        .subtle
                                        .resolveFrom(context),
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
