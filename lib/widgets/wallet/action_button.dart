import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class WalletActionButton extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String text;
  final double buttonSize;
  final double buttonIconSize;
  final double buttonFontSize;
  final EdgeInsets? margin;
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
    this.margin,
    this.shrink = 0.0,
    this.alt = false,
    this.loading = false,
    this.disabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final small = (1 - shrink) < 0.95;
    final buttonWidth = small ? 110.0 : buttonSize;

    final color = alt
        ? Theme.of(context).colors.surfacePrimary.resolveFrom(context)
        : Theme.of(context).colors.white;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: buttonSize + 40,
        width: buttonWidth,
        margin: margin,
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
                      ? Theme.of(context).colors.white
                      : Theme.of(context)
                          .colors
                          .surfacePrimary
                          .resolveFrom(context),
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  border: alt
                      ? Border.all(
                          color: Theme.of(context)
                              .colors
                              .surfacePrimary
                              .resolveFrom(context),
                          width: 3.0,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 10),
                    ),
                  ],
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
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 10),
                          customIcon ??
                              Icon(
                                icon,
                                size: 18,
                                color: color,
                              ),
                        ],
                      )
                    : Center(
                        child: customIcon ??
                            Icon(
                              icon,
                              size: buttonIconSize,
                              color: color,
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
                      color: Theme.of(context).colors.text.resolveFrom(context),
                      fontSize: buttonFontSize,
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
