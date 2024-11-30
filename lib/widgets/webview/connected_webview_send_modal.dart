import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ConnectedWebViewSendModal extends StatefulWidget {
  final String address;
  final String amount;
  final String? description;
  final String? successUrl;
  final String closeUrl;

  final WalletLogic walletLogic;
  final ProfilesLogic profilesLogic;

  final InAppWebViewController? webViewController;

  final double formattedAmount;
  final List<String>? descriptionItems;

  ConnectedWebViewSendModal({
    super.key,
    required this.address,
    required this.amount,
    this.description,
    required this.successUrl,
    required this.closeUrl,
    required this.walletLogic,
    required this.profilesLogic,
    this.webViewController,
  })  : formattedAmount = double.parse(amount) / 100,
        descriptionItems =
            description?.split('\n').map((e) => e.trim()).toList();

  @override
  State<ConnectedWebViewSendModal> createState() =>
      _ConnectedWebViewSendModalState();
}

class _ConnectedWebViewSendModalState extends State<ConnectedWebViewSendModal> {
  bool _isSending = false;

  void handleSend(
    BuildContext context,
    String address,
    double amount, {
    String? description,
    String? successUrl,
  }) async {
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

    final txHash = await walletLogic.sendTransaction(
      amount.toString(),
      address,
      message: description ?? '',
    );

    await Future.delayed(const Duration(milliseconds: 50));

    HapticFeedback.heavyImpact();

    if (txHash == null) {
      setState(() {
        _isSending = false;
      });

      return;
    }

    if (successUrl == null || successUrl.isEmpty) {
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
    }

    if (successUrl != null && successUrl.isNotEmpty) {
      String rawUrl = successUrl;
      if (rawUrl.contains('?')) {
        rawUrl = '$rawUrl&tx=$txHash';
      } else {
        rawUrl = '$rawUrl?tx=$txHash';
      }

      final closeUrl = Uri.encodeComponent(widget.closeUrl);
      rawUrl = '$rawUrl&close=$closeUrl';

      final uri = WebUri(rawUrl);

      widget.webViewController?.loadUrl(urlRequest: URLRequest(url: uri));

      navigator.pop();
    }

    setState(() {
      _isSending = false;
    });

    return;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final wallet = context.select(
      (WalletState state) => state.wallet,
    );

    final balance =
        double.tryParse(wallet != null ? wallet.balance : '0.0') ?? 0.0;

    final isSendingValid = balance >= double.parse(widget.amount);

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
                    widget.formattedAmount.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colors.text.resolveFrom(context),
                    ),
                  ),
                ],
              ),
              if (widget.description != null) const SizedBox(height: 20),
              if (widget.descriptionItems != null)
                ...widget.descriptionItems!.map(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSending)
                        const SizedBox(
                          height: 50,
                          width: 50,
                          child: CupertinoActivityIndicator(),
                        )
                      else
                        SlideToComplete(
                          onCompleted: !_isSending
                              ? () => handleSend(
                                    context,
                                    widget.address,
                                    widget.formattedAmount,
                                    description: widget.description,
                                    successUrl: widget.successUrl,
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
  }
}
