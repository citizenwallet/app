import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

class ConnectedWebViewCallDataModal extends StatefulWidget {
  final String address;
  final String value;
  final String calldata;
  final String? successUrl;
  final String closeUrl;

  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;

  final InAppWebViewController? webViewController;

  const ConnectedWebViewCallDataModal({
    super.key,
    required this.address,
    required this.value,
    required this.calldata,
    required this.successUrl,
    required this.closeUrl,
    required this.walletLogic,
    required this.profilesLogic,
    this.webViewController,
  });

  @override
  State<ConnectedWebViewCallDataModal> createState() =>
      _ConnectedWebViewCallDataModalState();
}

class _ConnectedWebViewCallDataModalState
    extends State<ConnectedWebViewCallDataModal> {
  bool _isConfirming = false;

  void handleConfirm(
    BuildContext context,
    String address,
    String value,
    String calldata, {
    String? successUrl,
  }) async {
    if (_isConfirming) {
      return;
    }

    final walletLogic = widget.walletLogic;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isConfirming = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    final txHash = await walletLogic.sendCallDataTransaction(
      address,
      value,
      calldata,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    if (txHash == null) {
      setState(() {
        _isConfirming = false;
      });

      return;
    }

    if (successUrl != null && successUrl.isNotEmpty) {
      String rawUrl = successUrl;
      if (rawUrl.contains('?')) {
        rawUrl = '$rawUrl&tx=$txHash';
      } else {
        rawUrl = '$rawUrl?tx=$txHash';
      }

      final closeUrl = Uri.encodeComponent(widget.closeUrl);
      if (rawUrl.contains('?')) {
        rawUrl = '$rawUrl&close=$closeUrl';
      } else {
        rawUrl = '$rawUrl?close=$closeUrl';
      }

      final uri = WebUri(rawUrl);

      widget.webViewController?.loadUrl(urlRequest: URLRequest(url: uri));
    }

    if (navigator.canPop()) {
      await Future.delayed(const Duration(milliseconds: 50));
      navigator.pop();
    }

    setState(() {
      _isConfirming = false;
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DismissibleModalPopup(
      modaleKey: 'connected_webview_send_modal',
      maxHeight: 240,
      paddingSides: 16,
      paddingTopBottom: 16,
      topRadius: 12,
      blockDismiss: false,
      child: SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 20,
                ),
                Text(
                  AppLocalizations.of(context)!.confirmAction,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colors.text.resolveFrom(context),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  AppLocalizations.of(context)!.confirmActionSub,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              width: width,
              child: SafeArea(
                child: BlurryChild(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colors
                              .subtle
                              .resolveFrom(context),
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isConfirming)
                          const SizedBox(
                            height: 50,
                            width: 50,
                            child: CupertinoActivityIndicator(),
                          )
                        else
                          SlideToComplete(
                            onCompleted: !_isConfirming
                                ? () => handleConfirm(
                                      context,
                                      widget.address,
                                      widget.value,
                                      widget.calldata,
                                      successUrl: widget.successUrl,
                                    )
                                : null,
                            enabled: true,
                            isComplete: _isConfirming,
                            completionLabel:
                                AppLocalizations.of(context)!.swipeToConfirm,
                            completionLabelColor: Theme.of(context)
                                .colors
                                .primary
                                .resolveFrom(context),
                            thumbColor: Theme.of(context)
                                .colors
                                .surfacePrimary
                                .resolveFrom(context),
                            width: width * 0.65,
                            child: SizedBox(
                              height: 50,
                              width: 50,
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.arrow_right,
                                  color: Theme.of(context).colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
