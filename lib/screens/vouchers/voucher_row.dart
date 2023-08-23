import 'package:citizenwallet/state/vouchers/logic.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';

class VoucherRow extends StatefulWidget {
  final Voucher voucher;
  final VoucherLogic logic;
  final bool active;
  final double size;
  final void Function(String, String, bool)? onTap;

  const VoucherRow({
    Key? key,
    required this.voucher,
    required this.logic,
    this.active = false,
    this.size = 60,
    this.onTap,
  }) : super(key: key);

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
    //
    widget.logic.updateVoucher(widget.voucher.address);
  }

  @override
  Widget build(BuildContext context) {
    final voucher = widget.voucher;
    final active = widget.active;
    final size = widget.size;
    final onTap = widget.onTap;

    final isRedeemed = (double.tryParse(voucher.balance) ?? 0) <= 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          width: 2,
          color: active
              ? ThemeColors.white
              : ThemeColors.uiBackgroundAlt.resolveFrom(context),
        ),
        color: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        borderRadius: const BorderRadius.all(
          Radius.circular(8.0),
        ),
      ),
      child: CupertinoButton(
        onPressed: () =>
            onTap?.call(voucher.address, voucher.balance, isRedeemed),
        color: ThemeColors.subtle.resolveFrom(context),
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ProfileCircle(
                  size: size,
                  backgroundColor: ThemeColors.white.resolveFrom(context),
                  imageUrl: 'assets/icons/voucher.svg',
                ),
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
                width: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: ThemeColors.white,
                ),
                child: Center(
                  child: isRedeemed
                      ? const Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 1,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: ThemeColors.black,
                                  size: 14,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 5,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.checkmark_alt,
                                  color: ThemeColors.black,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: ThemeColors.black,
                          size: 14,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
