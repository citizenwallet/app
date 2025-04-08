import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/chip.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/qr/qr.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class QRModal extends StatelessWidget {
  final String? title;
  final String qrCode;
  final String copyLabel;
  final String? externalLink;
  final void Function()? onCopy;

  const QRModal({
    super.key,
    this.title,
    required this.qrCode,
    this.copyLabel = '',
    this.externalLink,
    this.onCopy,
  });

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleOpenLink() {
    final Uri url = Uri.parse(externalLink ?? '/');

    launchUrl(url, mode: LaunchMode.inAppWebView);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final size = height > width ? width : height;
    final qrSize = size - 80;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 10, right: 10, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Header(
                title: title ?? AppLocalizations.of(context)!.wallet,
                actionButton: CupertinoButton(
                  padding: const EdgeInsets.all(5),
                  onPressed: () => handleDismiss(context),
                  child: Icon(
                    CupertinoIcons.xmark,
                    color:
                        Theme.of(context).colors.touchable.resolveFrom(context),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colors.white.resolveFrom(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: QR(
                        data: qrCode,
                        size: qrSize,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (onCopy != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            onTap: onCopy,
                            copyLabel,
                            color: Theme.of(context)
                                .colors
                                .subtleEmphasis
                                .resolveFrom(context),
                            textColor: Theme.of(context)
                                .colors
                                .touchable
                                .resolveFrom(context),
                            suffix: Icon(
                              CupertinoIcons.square_on_square,
                              size: 14,
                              color: Theme.of(context)
                                  .colors
                                  .touchable
                                  .resolveFrom(context),
                            ),
                            maxWidth: 180,
                          ),
                        ],
                      ),
                    const SizedBox(
                      height: 20,
                    ),
                    if (externalLink != null)
                      const SizedBox(
                        height: 20,
                      ),
                    if (externalLink != null)
                      Button(
                        text: '${AppLocalizations.of(context)!.viewContract} ',
                        suffix: const Icon(
                          CupertinoIcons.globe,
                        ),
                        onPressed: handleOpenLink,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
