import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/widgets/webview/webview_navigation.dart';

class WebViewModal extends StatefulWidget {
  final String? modalKey;
  final String url;
  final String redirectUrl;
  final String? customScheme;

  const WebViewModal({
    super.key,
    this.modalKey,
    required this.url,
    required this.redirectUrl,
    this.customScheme,
  });

  @override
  State<WebViewModal> createState() => _WebViewModalState();
}

class _WebViewModalState extends State<WebViewModal> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  HeadlessInAppWebView? headlessWebView;
  late InAppWebViewSettings settings;

  bool _show = false;
  bool _isDismissing = false;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();

    settings = InAppWebViewSettings(
      javaScriptEnabled: true,
      resourceCustomSchemes:
          widget.customScheme != null ? [widget.customScheme!] : [],
    );

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.url)),
      initialSettings: settings,
      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _show = false;
        });

        if (url == null) {
          return;
        }

        final uri = Uri.parse(url.toString());
        if (uri.toString() == widget.redirectUrl) {
          handleDismiss(context, path: uri.queryParameters['response']);
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        updateNavigationState();

        if (url == null) {
          return;
        }

        final uri = Uri.parse(url.toString());
        if (uri.toString() == widget.redirectUrl) {
          handleDismiss(context, path: uri.queryParameters['response']);
        }
      },
      onLoadResource: (controller, request) async {
        final uri = Uri.parse(request.url.toString());
        if (uri.toString() == widget.redirectUrl) {
          handleDismiss(context, path: uri.queryParameters['response']);
        }
      },
      onLoadResourceWithCustomScheme: (controller, request) async {
        final uri = Uri.parse(request.url.toString());
        handleDismiss(context, path: uri.queryParameters['response']);
        return null;
      },
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

  @override
  void dispose() {
    super.dispose();

    headlessWebView?.dispose();
    webViewController = null;
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

  void handleBack() async {
    await webViewController?.goBack();
  }

  void handleForward() async {
    await webViewController?.goForward();
  }

  void handleRefresh() async {
    await webViewController?.reload();
  }

  void handleRunWebView() async {
    if (headlessWebView == null || headlessWebView!.isRunning()) {
      return;
    }

    headlessWebView!.run();
  }

  void updateNavigationState() async {
    final canGoBack = await webViewController?.canGoBack() ?? false;
    final canGoForward = await webViewController?.canGoForward() ?? false;

    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
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
              height: 90 + safeTopPadding,
              padding: EdgeInsets.fromLTRB(0, safeTopPadding, 0, 0),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colors
                    .uiBackgroundAlt
                    .resolveFrom(context),
              ),
              child: WebViewNavigation(
                onDismiss: () => handleDismiss(context),
                onBack: handleBack,
                onForward: handleForward,
                onRefresh: handleRefresh,
                canGoBack: _canGoBack,
                canGoForward: _canGoForward,
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
                          onLoadStart: (controller, url) {
                            if (url == null) {
                              return;
                            }

                            final uri = Uri.parse(url.toString());
                            if (uri.toString() == widget.redirectUrl) {
                              handleDismiss(context,
                                  path: uri.queryParameters['response']);
                            }
                          },
                          onUpdateVisitedHistory:
                              (controller, url, androidIsReload) {
                            updateNavigationState();

                            if (url == null) {
                              return;
                            }

                            final uri = Uri.parse(url.toString());

                            if (uri.toString() == widget.redirectUrl) {
                              handleDismiss(context,
                                  path: uri.queryParameters['response']);
                            }
                          },
                          onLoadResource: (controller, request) async {
                            final uri = Uri.parse(request.url.toString());

                            if (uri.toString() == widget.redirectUrl) {
                              handleDismiss(context,
                                  path: uri.queryParameters['response']);
                            }
                          },
                          onLoadResourceWithCustomScheme:
                              (controller, request) async {
                            final uri = Uri.parse(request.url.toString());
                            handleDismiss(context,
                                path: uri.queryParameters['response']);
                            return null;
                          },
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
