import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VoucherRow extends StatefulWidget {
  final Voucher voucher;
  final VoucherLogic logic;
  final double size;
  final String? logo;
  final void Function(String, String, bool)? onTap;

  const VoucherRow({
    super.key,
    required this.voucher,
    required this.logic,
    this.size = 60,
    this.logo = 'assets/icons/voucher.svg',
    this.onTap,
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

    final isRedeemed = (double.tryParse(voucher.balance) ?? 0) <= 0;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 1,
            color: ThemeColors.subtleEmphasis.resolveFrom(context),
          ),
        ),
        color: ThemeColors.transparent.resolveFrom(context),
      ),
      child: CupertinoButton(
        onPressed: () =>
            onTap?.call(voucher.address, voucher.balance, isRedeemed),
        color: ThemeColors.transparent.resolveFrom(context),
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
                      Text(
                        voucher.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: ThemeColors.text.resolveFrom(context),
                        ),
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
                            color: ThemeColors.subtleText.resolveFrom(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Icon(
                    CupertinoIcons.ellipsis,
                    size: 18,
                    color: ThemeColors.touchable.resolveFrom(context),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 20,
                // width: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isRedeemed
                      ? ThemeColors.surfacePrimary
                      : ThemeColors.white,
                ),
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Center(
                    child: isRedeemed
                        ? Text(
                            AppLocalizations.of(context)!.redeemed,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.text,
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.issued,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ThemeColors.text,
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
