import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class TransactionStateIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color iconColor;
  final TransactionState state;
  final bool isIncoming;
  final int duration;

  const TransactionStateIcon({
    super.key,
    this.size = 20,
    this.color = ThemeColors.white,
    this.iconColor = ThemeColors.black,
    this.state = TransactionState.success,
    this.isIncoming = false,
    this.duration = 250,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
        duration: Duration(milliseconds: duration),
        height: size,
        width: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color,
        ),
        child: switch (state) {
          TransactionState.success => Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 2,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.checkmark_alt,
                      color: iconColor,
                      size: size * 0.6,
                    ),
                  ),
                ),
                Positioned(
                  left: 5.2,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.checkmark_alt,
                      color: iconColor,
                      size: size * 0.6,
                    ),
                  ),
                ),
              ],
            ),
          TransactionState.sending => Center(
              child: CupertinoActivityIndicator(
                color: iconColor,
                radius: size * 0.3,
              ),
            ),
          _ => Center(
              child: Icon(
                switch (state) {
                  TransactionState.pending => CupertinoIcons.checkmark_alt,
                  TransactionState.fail => CupertinoIcons.exclamationmark,
                  _ => CupertinoIcons.checkmark_alt,
                },
                color: iconColor,
                size: size * 0.6,
              ),
            )
        });
  }
}
