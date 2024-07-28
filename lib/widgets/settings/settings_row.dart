import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class SettingsRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final String? subLabel;
  final Widget? trailing;
  final void Function()? onTap;
  final IconData? onTapIcon;
  final String? place;

  const SettingsRow({
    super.key,
    required this.label,
    this.icon,
    this.iconColor,
    this.subLabel,
    this.trailing,
    this.onTap,
    this.onTapIcon,
    this.place,
  });

  @override
  Widget build(BuildContext context) {
    double brTop = 10;
    double brBottom = 10;
    double topWidth = 2;
    double bottomWidth = 2;

    if (place != null && place == "bottom") {
      brTop = 0;
      brBottom = 10;
      topWidth = 1;
    }

    if (place != null && place == "top") {
      brTop = 10;
      brBottom = 0;
      bottomWidth = 1;
    }

    if (place != null && place == "middle") {
      brTop = 0;
      brBottom = 0;
      topWidth = 1;
      bottomWidth = 1;
    }

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  decoration: BoxDecoration(
                      color: ThemeColors.background.resolveFrom(context),
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(brTop),
                          topRight: Radius.circular(brTop),
                          bottomLeft: Radius.circular(brBottom),
                          bottomRight: Radius.circular(brBottom)),
                      border: Border(
                        top: BorderSide(
                          color: ThemeColors.border.resolveFrom(context),
                          width: topWidth,
                        ),
                        bottom: BorderSide(
                          color: ThemeColors.border.resolveFrom(context),
                          width: bottomWidth,
                        ),
                        left: BorderSide(
                          color: ThemeColors.border.resolveFrom(context),
                          width: 2,
                        ),
                        right: BorderSide(
                          color: ThemeColors.border.resolveFrom(context),
                          width: 2,
                        ),
                      )),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Padding(
                          padding: const EdgeInsets.all(5),
                          // child: SvgPicture.asset(
                          //   icon!,
                          //   colorFilter: iconColor != null
                          //       ? ColorFilter.mode(
                          //           iconColor!,
                          //           BlendMode.srcIn,
                          //         )
                          //       : null,
                          //   semanticsLabel: '$label icon',
                          //   height: 20,
                          //   width: 20,
                          // ),
                          child: Icon(icon,
                              size: 25,
                              color:
                                  ThemeColors.subtleSolid.resolveFrom(context)),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                      if (onTap != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                          child: Icon(
                            onTapIcon ?? CupertinoIcons.forward,
                            color:
                                ThemeColors.subtleEmphasis.resolveFrom(context),
                          ),
                        ),
                    ],
                  ),
                ),
                if (subLabel != null) const SizedBox(height: 5),
                if (subLabel != null)
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 10),
                          child: Text(
                            subLabel!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color:
                                  ThemeColors.subtleText.resolveFrom(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
