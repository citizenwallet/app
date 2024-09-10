import 'dart:async';

enum NFCScannerDirection { top, right, bottom, left }

abstract class NFCService {
  NFCScannerDirection get direction;

  Future<void> printReceipt(
      {String? amount, String? symbol, String? description, String? link});

  Future<String> readSerialNumber({String? message, String? successMessage});

  Future<void> stop();

  Future<bool> isAvailable();
}
