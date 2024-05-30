import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:flutter/cupertino.dart';

class WalletActionButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String text;
  final double buttonSize;
  final double buttonIconSize;
  final double buttonFontSize;
  final double shrink;
  final bool alt;
  final bool loading;
  final bool disabled;
  final void Function()? onPressed;

  const WalletActionButton({
    super.key,
    this.icon,
    this.customIcon,
    required this.text,
    this.buttonSize = 60,
    this.buttonIconSize = 40,
    this.buttonFontSize = 14,
    this.shrink = 0.0,
    this.alt = false,
    this.loading = false,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final small = (1 - shrink) < 0.4;
    final buttonWidth = progressiveClamp(buttonSize, 120, (1 - shrink));

    return SizedBox(
      height: buttonSize + 40,
      width: buttonWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: disabled ? () => () : onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: buttonSize,
              width: buttonWidth,
              decoration: BoxDecoration(
                color: alt
                    ? ThemeColors.surfaceBackground.resolveFrom(context)
                    : ThemeColors.surfacePrimary.resolveFrom(context),
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              child: small
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: disabled
                                ? ThemeColors.subtleEmphasis
                                : alt
                                    ? ThemeColors.surfacePrimary
                                        .resolveFrom(context)
                                    : ThemeColors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 10),
                        customIcon ??
                            Icon(
                              icon,
                              size: 18,
                              color: disabled
                                  ? ThemeColors.subtle
                                  : alt
                                      ? ThemeColors.surfacePrimary
                                          .resolveFrom(context)
                                      : ThemeColors.white,
                            ),
                      ],
                    )
                  : Center(
                      child: customIcon ??
                          Icon(
                            icon,
                            size: buttonIconSize,
                            color: disabled
                                ? ThemeColors.subtle
                                : alt
                                    ? ThemeColors.surfacePrimary
                                        .resolveFrom(context)
                                    : ThemeColors.white,
                          ),
                    ),
            ),
          ),
          if (!small)
            Expanded(
              child: Center(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: disabled
                        ? ThemeColors.subtleEmphasis
                        : ThemeColors.black,
                    fontSize: buttonFontSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
