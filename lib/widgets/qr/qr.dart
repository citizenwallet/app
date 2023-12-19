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

    return SizedBox(
      height: size,
      width: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: QrImageView(
          data: data,
          size: size,
          gapless: false,
          version: QrVersions.auto,
          backgroundColor: ThemeColors.white,
          padding: padding,
          eyeStyle: const QrEyeStyle(
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
