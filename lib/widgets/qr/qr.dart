import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QR extends StatelessWidget {
  final String data;
  final double size;
  final String? logo;

  const QR({
    Key? key,
    required this.data,
    this.size = 200,
    this.logo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageSize = size * 0.2;

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: QrImageView(
        data: data,
        size: size,
        gapless: false,
        version: QrVersions.auto,
        backgroundColor: ThemeColors.white,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: ThemeColors.primary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: ThemeColors.black,
        ),
        embeddedImage: AssetImage(logo ?? 'assets/logo.png'),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(imageSize, imageSize),
        ),
      ),
    );
  }
}
