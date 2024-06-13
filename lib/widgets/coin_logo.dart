import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
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
        color: Theme.of(context).colors.white,
        border: Border.all(
          width: 1,
          color: Theme.of(context).colors.subtle.resolveFrom(context),
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
