import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/qr.dart';
import 'package:citizenwallet/widgets/webview/connected_webview_send_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/widgets/webview/webview_navigation.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ConnectedWebViewModal extends StatefulWidget {
  final String? modalKey;
  final String url;
  final String redirectUrl;
  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;

  const ConnectedWebViewModal({
    super.key,
    this.modalKey,
    required this.url,
    required this.redirectUrl,
    required this.walletLogic,
    required this.profilesLogic,
  });

  @override
  State<ConnectedWebViewModal> createState() => _WebViewModalState();
}

class _WebViewModalState extends State<ConnectedWebViewModal> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  HeadlessInAppWebView? headlessWebView;
  late InAppWebViewSettings settings;

  bool _show = false;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    settings = InAppWebViewSettings(
      javaScriptEnabled: true,
    );

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: settings,
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      shouldOverrideUrlLoading: shouldOverrideUrlLoading,
      onLoadStop: (controller, url) {
        setState(() {
          _show = true;
        });
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      handleRunWebView();
    });
  }

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
      InAppWebViewController controller, NavigationAction action) async {
    final uri = Uri.parse(action.request.url.toString());
    if (uri.toString().startsWith(widget.redirectUrl)) {
      handleDisplayActionModal(uri);

      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  @override
  void dispose() {
    super.dispose();

    headlessWebView?.dispose();
    webViewController = null;
  }

  void handleDisplayActionModal(Uri uri) async {
    final format = parseQRFormat(uri.toString());
    if (format != QRFormat.sendtoUrl) {
      return;
    }

    final (address, amount, description, _) = parseQRCode(uri.toString());
    final successUrl = uri.queryParameters['success'];
    if (amount == null || description == null) {
      return;
    }

    widget.profilesLogic.getProfile(address);

    final dismiss = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      builder: (context) => ConnectedWebViewSendModal(
        address: address,
        amount: amount,
        description: description,
        successUrl: successUrl,
        walletLogic: widget.walletLogic,
        profilesLogic: widget.profilesLogic,
      ),
    );

    if (dismiss == true && super.mounted) {
      handleDismiss(context);
    }
  }

  void handleDismiss(BuildContext context, {String? path}) async {
    if (_isDismissing) {
      return;
    }

    _isDismissing = true;

    webViewController?.stopLoading();

    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 250));

    navigator.pop(path);
  }

  void handleBack({InAppWebViewController? controller}) async {
    await (controller ?? webViewController)?.goBack();
  }

  void handleForward({InAppWebViewController? controller}) async {
    await (controller ?? webViewController)?.goForward();
  }

  void handleRefresh({InAppWebViewController? controller}) async {
    await (controller ?? webViewController)?.reload();
  }

  void handleRunWebView() async {
    if (headlessWebView == null || headlessWebView!.isRunning()) {
      return;
    }

    headlessWebView!.run();
  }

  @override
  Widget build(BuildContext context) {
    final safeTopPadding = MediaQuery.of(context).padding.top;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: Flex(
          direction: Axis.vertical,
          children: [
            Container(
              height: 44 + safeTopPadding,
              padding: EdgeInsets.fromLTRB(0, safeTopPadding, 0, 0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colors
                    .uiBackgroundAlt
                    .resolveFrom(context),
              ),
              child: WebViewNavigation(
                onDismiss: () => handleDismiss(context),
                canGoBack: true,
                canGoForward: true,
              ),
            ),
            Expanded(
                child: Stack(
              children: [
                AnimatedOpacity(
                  opacity: _show ? 1 : 0,
                  duration: const Duration(milliseconds: 750),
                  child: _show
                      ? InAppWebView(
                          key: webViewKey,
                          headlessWebView: headlessWebView,
                          initialUrlRequest:
                              URLRequest(url: WebUri(widget.url)),
                          initialSettings: settings,
                          onWebViewCreated: (controller) {
                            headlessWebView = null;
                            webViewController = controller;
                          },
                          shouldOverrideUrlLoading: shouldOverrideUrlLoading,
                          onLoadStop: (controller, url) {
                            setState(() {
                              _show = true;
                            });
                          },
                        )
                      : const SizedBox(),
                ),
                if (!_show)
                  Center(
                    child: CupertinoActivityIndicator(
                      color:
                          Theme.of(context).colors.primary.resolveFrom(context),
                      radius: 15,
                    ),
                  ),
              ],
            )),
          ],
        ),
      ),
    );
  }
}
