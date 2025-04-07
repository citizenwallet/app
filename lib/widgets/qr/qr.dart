import 'package:citizenwallet/theme/provider.dart';
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
        color: Theme.of(context).colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).colors.primary,
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
          backgroundColor: Theme.of(context).colors.white,
          padding: padding,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.circle,
            color: Theme.of(context).colors.primary,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.circle,
            color: Theme.of(context).colors.black,
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
