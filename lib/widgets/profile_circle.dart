import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';

class ProfileCircle extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double padding;
  final double? borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;

  const ProfileCircle({
    Key? key,
    this.imageUrl,
    this.size = 50,
    this.padding = 0,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final asset = imageUrl ?? 'assets/icons/profile.svg';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? CupertinoColors.systemGrey5,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? CupertinoColors.systemGrey5,
          width: borderWidth ?? 0,
        ),
      ),
      padding: EdgeInsets.all(padding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: asset.endsWith('.svg')
            ? SvgPicture.asset(
                asset,
                semanticsLabel: 'profile icon',
                height: size,
                width: size,
              )
            : Image.asset(
                asset,
                semanticLabel: 'profile icon',
                height: size,
                width: size,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
