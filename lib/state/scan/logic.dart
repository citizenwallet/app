import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/nfc/default.dart';
import 'package:citizenwallet/services/nfc/service.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/scan/state.dart';
import 'package:web3dart/web3dart.dart';

class ScanLogic extends WidgetsBindingObserver {
  static final ScanLogic _instance = ScanLogic._internal();

  factory ScanLogic() {
    return _instance;
  }

  ScanLogic._internal();
  late ScanState _state;
  final NFCService _nfc = DefaultNFCService();

  EthPrivateKey? _currentCredentials;
  EthereumAddress? _currentAccount;
  Config? _currentConfig;

  static void setGlobalWalletState(Config config, EthPrivateKey credentials, EthereumAddress account) {
    _instance.setWalletState(config, credentials, account);
  }

  void init(BuildContext context) {
    _state = context.read<ScanState>();
  }

  void setWalletState(Config config, EthPrivateKey credentials, EthereumAddress account) {
    _currentConfig = config;
    _currentCredentials = credentials;
    _currentAccount = account;
  }

  void load() async {
    try {
      _state.loadScanner();
      _state.scannerDirection = _nfc.direction;

      final isAvailable = await _nfc.isAvailable();

      if (!isAvailable) {
        _state.scannerNotAvailable();
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
      if (_currentConfig == null || _currentCredentials == null || _currentAccount == null) {
        throw Exception('Wallet not initialized');
      }

      _state.setNfcAddressRequest();

      _state.setNfcReading(true);

      final serialNumber = await _nfc.readSerialNumber(
        message: message,
        successMessage: successMessage,
      );

      _state.setNfcReading(false); //

      final cardHash = await getCardHash(_currentConfig!, serialNumber);
      final address = await getCardAddress(_currentConfig!, cardHash);

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

  void cancelScan({bool notify = true}) {
    _nfc.stop();
    _state.setNfcReading(false, notify: notify);
    _state.setNfcAddressSuccess(null, notify: notify);
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
