import 'package:flutter/material.dart';
import 'package:citizenwallet/services/nfc/service.dart';

enum ScanStateType {
  loading,
  ready,
  notReady,
  readingNFC,
  error,
  notAvailable,
}

class ScanState with ChangeNotifier {
  ScanStateType status = ScanStateType.loading;
  String statusError = '';

  NFCScannerDirection scannerDirection = NFCScannerDirection.top;

  bool get loading => status == ScanStateType.loading;

  bool get ready => status == ScanStateType.ready;

  void setScannerDirection(NFCScannerDirection direction) {
    scannerDirection = direction;
    notifyListeners();
  }

  void loadScanner() {
    status = ScanStateType.loading;
    notifyListeners();
  }

  void scannerReady() {
    status = ScanStateType.ready;
    notifyListeners();
  }

  void scannerNotReady() {
    status = ScanStateType.notReady;
    notifyListeners();
  }

  void scannerNotAvailable() {
    status = ScanStateType.notAvailable;
    notifyListeners();
  }

  void updateStatus(ScanStateType status) {
    this.status = status;
    notifyListeners();
  }

  void setStatusError(ScanStateType status, String error) {
    this.status = status;
    statusError = error;
    notifyListeners();
  }

  String? nfcAddress;
  String? nfcBalance;

  bool nfcAddressLoading = false;
  bool nfcAddressError = false;

  void setNfcAddressRequest() {
    nfcAddressLoading = true;
    nfcAddressError = false;
    notifyListeners();
  }

  void setNfcAddressSuccess(String? address) {
    nfcAddress = address;
    nfcAddressLoading = false;
    nfcAddressError = false;
    notifyListeners();
  }

  void setAddressBalance(String? balance) {
    nfcBalance = balance;
    notifyListeners();
  }

  void setNfcAddressError() {
    nfcAddressError = true;
    nfcAddressLoading = false;
    notifyListeners();
  }

  bool nfcReading = false;

  void setNfcReading(bool reading, {bool notify = true}) {
    nfcReading = reading;
    if (notify) notifyListeners();
  }
}
