import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoinLogo extends StatelessWidget {
  final double size;
  final String? logo;

  const CoinLogo({
    super.key,
    required this.size,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        color: Colors.white,
        border: Border.all(
          width: 1,
          color: ThemeColors.subtle.resolveFrom(context),
        ),
      ),
      child: logo != null
          ? SvgPicture.network(
              logo!,
              placeholderBuilder: (context) =>
                  SvgPicture.asset('assets/logo.svg'),
            )
          : SvgPicture.asset('assets/logo.svg'),
    );
  }
}
