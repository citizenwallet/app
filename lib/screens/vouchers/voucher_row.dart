import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoucherRow extends StatefulWidget {
  final Voucher voucher;
  final VoucherLogic logic;
  final double size;
  final String? logo;
  final void Function(String, String, String?, bool)? onTap;
  final void Function(String, String, String?, bool)? onMore;

  const VoucherRow({
    super.key,
    required this.voucher,
    required this.logic,
    this.size = 60,
    this.logo = 'assets/icons/voucher.svg',
    this.onTap,
    this.onMore,
  });

  @override
  VoucherRowState createState() => VoucherRowState();
}

class VoucherRowState extends State<VoucherRow> {
  @override
  void initState() {
    super.initState();

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  void onLoad() async {
    widget.logic.updateVoucher(widget.voucher.address);
  }

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    final size = widget.size;
    final onTap = widget.onTap;
    final onMore = widget.onMore;

    final isRedeemed = (double.tryParse(voucher.balance) ?? 0) <= 0;

    final formattedAmount = voucher.formattedBalance;

    debugPrint(
        'balance ${voucher.balance} formattedBalance $formattedAmount isRedeemed $isRedeemed');

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: Theme.of(context).colors.subtleEmphasis.resolveFrom(context),
          ),
        ),
        color: Theme.of(context).colors.transparent.resolveFrom(context),
      ),
      child: CupertinoButton(
        onPressed: () => onTap?.call(
            voucher.address, formattedAmount, widget.logo, isRedeemed),
        color: Theme.of(context).colors.transparent.resolveFrom(context),
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CoinLogo(size: size, logo: widget.logo),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .voucherFor(formattedAmount),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context)
                                  .colors
                                  .text
                                  .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          CoinLogo(size: 16, logo: widget.logo),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                        child: Text(
                          voucher.formattedAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context)
                                .colors
                                .subtleText
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onMore != null)
                  GestureDetector(
                    onTap: () => onMore(voucher.address, formattedAmount,
                        widget.logo, isRedeemed),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        size: 18,
                        color: Theme.of(context)
                            .colors
                            .touchable
                            .resolveFrom(context),
                      ),
                    ),
                  )
              ],
            ),
            Positioned(
              bottom: 0,
              right: 50,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isRedeemed
                      ? Theme.of(context).colors.surfacePrimary
                      : Theme.of(context).colors.white,
                ),
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Center(
                    child: isRedeemed
                        ? Text(
                            AppLocalizations.of(context)!.redeemed,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colors.text,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.issued,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colors.text,
                            ),
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
