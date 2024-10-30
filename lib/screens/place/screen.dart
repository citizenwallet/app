import 'dart:typed_data';

import 'package:citizenwallet/screens/place/amount.dart';
import 'package:citizenwallet/state/amount/selectors.dart';
import 'package:citizenwallet/state/amount/state.dart';
import 'package:citizenwallet/state/scan/logic.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/scanner/nfc_modal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PlaceChargeManual extends StatefulWidget {
  final WalletLogic walletLogic;

  const PlaceChargeManual({super.key, required this.walletLogic});

  @override
  PlaceChargeManualState createState() => PlaceChargeManualState();
}

class PlaceChargeManualState extends State<PlaceChargeManual> {
  late ScanLogic _scanLogic;

  @override
  void initState() {
    super.initState();

    _scanLogic = ScanLogic();

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  @override
  void dispose() {
    _scanLogic.cancelScan(notify: false);
    widget.walletLogic.clearReceiveQR(notify: false);

    super.dispose();
  }

  void onLoad() async {
    _scanLogic.init(context);
    _scanLogic.load();
  }

  void handleScanCard(BuildContext context, String formattedAmount) async {
    FocusManager.instance.primaryFocus?.unfocus();

    final result = await showCupertinoModalPopup<(Uint8List?, String?)?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const NFCModal(
        modalKey: 'send-nfc-scanner',
      ),
    );

    // the iOS NFC Modal sets the app to inactive and then resumes it
    // this causes transactions to start being requested again
    // this is a workaround to wait for the app to resume before pausing the fetching
    if (isPlatformApple()) {
      // iOS needs an extra delay which is the time it takes to close the NFC modal
      delay(const Duration(seconds: 1)).then((_) {
        widget.walletLogic.pauseFetching();
      });
    }

    widget.walletLogic.pauseFetching();

    if (result == null) {
      return;
    }

    final (hash, address) = result;
    if (hash == null || address == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    widget.walletLogic.chargeFrom(
      hash,
      address,
      formattedAmount,
    );

    final navigator = GoRouter.of(context);

    await navigator
        .push('/wallet/${widget.walletLogic.account}/charge/$address/progress');
  }

  void handleScanQRCode(String formattedAmount) {
    print('scan qr code, formatted amount: $formattedAmount');

    widget.walletLogic.updateReceiveQR(formattedAmount: formattedAmount);

    final navigator = GoRouter.of(context);
    navigator.push('/wallet/${widget.walletLogic.account}/charge/qr');
  }

  @override
  Widget build(BuildContext context) {
    final formattedAmount = context.select(selectFormattedAmount);

    final zeroAmount = formattedAmount.isEmpty || formattedAmount == '0.00';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  title: AppLocalizations.of(context)!.chargeManual,
                  showBackButton: true,
                ),
              ),
              Expanded(
                child: AmountEntry(),
              ),
              Button(
                text: AppLocalizations.of(context)!.scanCard,
                onPressed: !zeroAmount
                    ? () => handleScanCard(context, formattedAmount)
                    : null,
                labelColor: Theme.of(context).colors.white.resolveFrom(context),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    CupertinoIcons.creditcard,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Button(
                text: AppLocalizations.of(context)!.displayQRCode,
                onPressed: !zeroAmount
                    ? () => handleScanQRCode(formattedAmount)
                    : null,
                labelColor: Theme.of(context).colors.white.resolveFrom(context),
                suffix: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(
                    CupertinoIcons.qrcode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
