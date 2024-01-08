import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';

class WebViewModal extends StatefulWidget {
  final String url;
  final String customScheme;

  const WebViewModal({
    super.key,
    required this.url,
    required this.customScheme,
  });

  @override
  State<WebViewModal> createState() => _WebViewModalState();
}

class _WebViewModalState extends State<WebViewModal> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  late InAppWebViewSettings settings;

  @override
  void initState() {
    super.initState();

    settings = InAppWebViewSettings(
      javaScriptEnabled: true,
      resourceCustomSchemes: [widget.customScheme],
    );
  }

  void handleDismiss(BuildContext context, {String? path}) async {
    webViewController?.stopLoading();
    webViewController?.dispose();

    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 250));

    navigator.pop(path);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                    initialSettings: settings,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadResourceWithCustomScheme:
                        (controller, request) async {
                      final uri = Uri.parse(request.url.toString());
                      handleDismiss(context,
                          path: uri.queryParameters['response']);
                      return null;
                    },
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: ThemeColors.uiBackground
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
                            CupertinoIcons.xmark,
                            color: ThemeColors.touchable.resolveFrom(context),
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
