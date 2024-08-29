import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/services/nfc/default.dart';
import 'package:citizenwallet/services/nfc/service.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/scan/state.dart';

class ScanLogic extends WidgetsBindingObserver {
  static final ScanLogic _instance = ScanLogic._internal();

  factory ScanLogic() {
    return _instance;
  }

  ScanLogic._internal();
  late ScanState _state;
  final NFCService _nfc = DefaultNFCService();

  final WalletService _wallet = WalletService();

  void init(BuildContext context) {
    _state = context.read<ScanState>();
  }

  void load() async {
    try {
      _state.loadScanner();
      _state.scannerDirection = _nfc.direction;

      final isAvailable = await _nfc.isAvailable();

      if (!isAvailable) {
        _state.scannerNotReady();
        return;
      }

      _state.scannerReady();
      return;
    } catch (e, s) {
      debugPrint('Error loading config: $e');
      debugPrint('Stacktrace: $s');
    }

    _state.scannerNotReady();
  }

  Future<String?> read({String? message, String? successMessage}) async {
    try {
      _state.setNfcAddressRequest();

      _state.setNfcReading(true); 

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      _state.setNfcReading(false); //

      final cardHash = await _wallet.getCardHash(serialNumber);
      final address = await _wallet.getCardAddress(cardHash);

      _state.setNfcAddressSuccess(address.hexEip55);

      return address.hexEip55;
    } catch (e, s) {
      debugPrint('Error reading NFC: $e');
      debugPrint('Stacktrace: $s');
      _state.setNfcAddressError();
      _state.setAddressBalance(null);
      _state.setNfcReading(false);
    }

    return null;
  }

  void cancelScan() {
    _nfc.stop();
    _state.setNfcReading(false, notify: false);
  }

  bool wasRunning = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      default:
    }
  }
}
