import 'package:cached_network_image/cached_network_image.dart';
import 'package:citizenwallet/widgets/loaders/progress_circle.dart';
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
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.size = 50,
    this.padding = 0,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final String asset = imageUrl != null && imageUrl != ''
        ? imageUrl!
        : 'assets/icons/profile.png';

    final network = asset.startsWith('http');

    if (kDebugMode && asset.endsWith('.svg') && network) {
      return SvgPicture.asset(
        'assets/logo.svg',
        height: size,
        width: size,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
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
                  ? network && !kDebugMode
                      ? SvgPicture.network(
                          asset,
                          semanticsLabel: 'profile icon',
                          height: size,
                          width: size,
                          placeholderBuilder: (_) => SvgPicture.asset(
                            'assets/logo.svg',
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
                  : Stack(
                      children: [
                        if (!network)
                          Image.asset(
                            asset,
                            semanticLabel: 'profile icon',
                            height: size,
                            width: size,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/icons/profile.png',
                              semanticLabel: 'profile icon',
                              height: size,
                              width: size,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (network) ...[
                          CachedNetworkImage(
                            imageUrl: asset,
                            height: size,
                            width: size,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, progress) => ProgressCircle(
                              progress: progress.progress ?? 0,
                              size: size,
                            ),
                            errorWidget: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/icons/profile.png',
                              semanticLabel: 'profile icon',
                              height: size,
                              width: size,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ]
                      ],
                    ),
            ),
    );
  }
}
