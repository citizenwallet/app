import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/qr.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/widgets/webview/webview_navigation.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';

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

  String? _url;
  bool _show = false;
  bool _isDismissing = false;

  bool _isSending = false;

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
      onUpdateVisitedHistory: (controller, url, androidIsReload) {
        if (url == null) {
          return;
        }

        setState(() {
          _url = url.toString();
        });
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

  void handleSend(BuildContext context, String address, double amount,
      String description) async {
    if (_isSending) {
      return;
    }

    final walletLogic = widget.walletLogic;

    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    final navigator = GoRouter.of(context);

    walletLogic.sendTransaction(
      amount.toString(),
      address,
      message: description,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    final sent = await navigator.push<bool?>(
      '/wallet/${walletLogic.account}/send/$address/progress',
    );

    if (sent == true) {
      walletLogic.clearInputControllers();
      walletLogic.resetInputErrorState();
      widget.profilesLogic.clearSearch();

      await Future.delayed(const Duration(milliseconds: 50));

      navigator.pop(true);
      return;
    }

    setState(() {
      _isSending = false;
    });

    return;
  }

  void handleDisplayActionModal(Uri uri) async {
    final format = parseQRFormat(uri.toString());
    if (format != QRFormat.sendtoUrl) {
      return;
    }

    final (address, amount, description, _) = parseQRCode(uri.toString());
    if (amount == null || description == null) {
      return;
    }

    final formattedAmount = double.parse(amount) / 100;
    final descriptionItems =
        description.split(',').map((e) => e.trim()).toList();

    widget.profilesLogic.getProfile(address);

    final sent = await showCupertinoModalBottomSheet<bool?>(
      context: context,
      builder: (context) {
        final width = MediaQuery.of(context).size.width;

        final wallet = context.select(
          (WalletState state) => state.wallet,
        );
        final balance =
            double.tryParse(wallet != null ? wallet.balance : '0.0') ?? 0.0;

        final isSendingValid = balance >= double.parse(amount);

        final selectedProfile = context.select(
          (ProfilesState state) => state.selectedProfile,
        );

        return SizedBox(
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
                  ProfileCircle(
                    imageUrl: selectedProfile?.imageSmall,
                    size: 120,
                  ),
                  Text(
                    selectedProfile?.name ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '@${selectedProfile?.username ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          0,
                          0,
                          0,
                        ),
                        child: CoinLogo(
                          size: 32,
                          logo: wallet?.currencyLogo,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedAmount.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...descriptionItems.map(
                    (e) => Text(
                      e,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
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
                        children: [
                          SlideToComplete(
                            onCompleted: !_isSending
                                ? () => handleSend(
                                      context,
                                      address,
                                      formattedAmount,
                                      description,
                                    )
                                : null,
                            enabled: isSendingValid,
                            isComplete: _isSending,
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
        );
      },
    );

    if (sent == true && super.mounted) {
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
                          onUpdateVisitedHistory:
                              (controller, url, androidIsReload) {
                            if (url == null) {
                              return;
                            }

                            setState(() {
                              _url = url.toString();
                            });
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
