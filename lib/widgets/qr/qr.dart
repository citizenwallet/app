import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QR extends StatelessWidget {
  final String data;
  final double size;
  final EdgeInsets padding;
  final String? logo;

  const QR({
    super.key,
    required this.data,
    this.size = 200,
    this.padding = const EdgeInsets.all(10),
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    final imageSize = size * 0.2;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: ThemeColors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: ThemeColors.primary,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: QrImageView(
          data: data,
          size: size,
          gapless: false,
          version: QrVersions.auto,
          backgroundColor: ThemeColors.white,
          padding: padding,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: ThemeColors.primary,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: ThemeColors.black,
          ),
          embeddedImage: logo != null ? AssetImage(logo!) : null,
          embeddedImageStyle: QrEmbeddedImageStyle(
            size: Size(imageSize, imageSize),
          ),
        ),
      ),
    );
  }
}
