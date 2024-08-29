import 'package:citizenwallet/state/scan/logic.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/widgets/nfc_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class NFCModal extends StatefulWidget {
  final String? modalKey;
  final bool confirm;

  const NFCModal({
    super.key,
    this.modalKey,
    this.confirm = false,
  });

  @override
  NFCModalState createState() => NFCModalState();
}

class NFCModalState extends State<NFCModal>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScanLogic _scanLogic = ScanLogic();

  @override
  void initState() {
    super.initState();

    // Start listening to lifecycle changes.
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here

      onLoad();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
      // Restart the scanner when the app is resumed.
      // Don't forget to resume listening to the barcode events.

      case AppLifecycleState.inactive:
      // Stop the scanner when the app is paused.
      // Also stop the barcode events subscription.
    }
  }

  void onLoad() async {
    final address = await _scanLogic.read();

    _textController.text = address ?? '';

    goToSubmit();
  }

  @override
  void dispose() {
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    _scanLogic.cancelScan();
    GoRouter.of(context).pop();
  }

  void goToSubmit() {
    handleSubmit(context);
  }

  void handleSubmit(BuildContext context) async {
    final navigator = GoRouter.of(context);

    await delay(const Duration(milliseconds: 1000));

    if (_textController.value.text.isNotEmpty) {
      navigator.pop(_textController.value.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NfcOverlay(
      onCancel: () => handleDismiss(context),
    );
  }
}