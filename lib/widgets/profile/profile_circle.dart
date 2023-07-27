import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/svg.dart';

class ProfileCircle extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final double size;
  final double padding;
  final double? borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;

  const ProfileCircle({
    Key? key,
    this.imageUrl,
    this.imageBytes,
    this.size = 50,
    this.padding = 0,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final asset = imageUrl ?? 'assets/icons/profile.svg';

    final network = asset.startsWith('http');

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
      child: imageBytes != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: Image(
                image: MemoryImage(imageBytes!),
                semanticLabel: 'profile icon',
                height: size,
                width: size,
                fit: BoxFit.cover,
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(size / 2),
              child: asset.endsWith('.svg')
                  ? network
                      ? SvgPicture.network(
                          asset,
                          semanticsLabel: 'profile icon',
                          height: size,
                          width: size,
                          placeholderBuilder: (_) => PulsingContainer(
                            height: size,
                            width: size,
                          ),
                        )
                      : SvgPicture.asset(
                          asset,
                          semanticsLabel: 'profile icon',
                          height: size,
                          width: size,
                        )
                  : network
                      ? Image.network(
                          asset,
                          semanticLabel: 'profile icon',
                          height: size,
                          width: size,
                          fit: BoxFit.cover,
                          frameBuilder: (_, child, frame, loaded) => loaded
                              ? child
                              : AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  child: frame == null
                                      ? PulsingContainer(
                                          height: size,
                                          width: size,
                                        )
                                      : child,
                                ),
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
