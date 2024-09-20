import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:zikzak_inappwebview/zikzak_inappwebview.dart';
import 'package:go_router/go_router.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String redirectUrl;
  final String? customScheme;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.redirectUrl,
    this.customScheme,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
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
        if (url == null) {
          return;
        }

        final uri = Uri.parse(url.toString());
        if (uri.toString() == widget.redirectUrl) {
          handleDismiss(context, path: uri.queryParameters['response']);
        }
      },
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
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

  void handleRunWebView() async {
    if (headlessWebView == null || headlessWebView!.isRunning()) {
      return;
    }

    await delay(const Duration(milliseconds: 250));

    headlessWebView!.run();

    await delay(const Duration(milliseconds: 250));

    setState(() {
      _show = true;
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
                          )
                        : const SizedBox(),
                  ),
                  Positioned(
                    top: safeTopPadding,
                    left: 0,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colors
                            .uiBackground
                            .resolveFrom(context)
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Center(
                        child: CupertinoButton(
                          padding: const EdgeInsets.all(5),
                          onPressed: () => handleDismiss(context),
                          child: Icon(
                            CupertinoIcons.back,
                            color: Theme.of(context)
                                .colors
                                .touchable
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
