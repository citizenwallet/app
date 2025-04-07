import 'dart:async';
import 'dart:io';

import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:citizenwallet/services/nfc/service.dart';

class DefaultNFCService implements NFCService {
  @override
  NFCScannerDirection get direction =>
      Platform.isAndroid ? NFCScannerDirection.right : NFCScannerDirection.top;

  @override
  Future<void> printReceipt(
      {String? amount,
      String? symbol,
      String? description,
      String? link}) async {}

  @override
  Future<String> readSerialNumber(
      {String? message, String? successMessage}) async {
    // Check availability
    bool isAvailable = await NfcManager.instance.isAvailable();

    if (!isAvailable) {
      throw Exception('NFC is not available');
    }

    final completer = Completer<String>();

    NfcManager.instance.startSession(
      alertMessage: message ?? 'Scan to confirm',
      onDiscovered: (NfcTag tag) async {
        final List<int>? identifier = _findIdentifier(tag.data);
        if (identifier == null) {
          if (completer.isCompleted) return;
          completer.completeError('Invalid tag');
          return;
        }

        String uid = identifier
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join();

        if (completer.isCompleted) return;

        await NfcManager.instance
            .stopSession(alertMessage: successMessage ?? 'Confirmed');

        if (isPlatformApple()) {
          await delay(const Duration(milliseconds: 2000));
        }

        completer.complete(uid);
      },
      onError: (error) async {
        if (completer.isCompleted) return;
        completer.completeError(error); // Complete the Future with the error
      },
    );

    return completer.future;
  }

  @override
  Future<void> stop() async {
    await NfcManager.instance.stopSession();
  }

  @override
  Future<bool> isAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  List<int>? _findIdentifier(Map<String, dynamic> data) {
    if (data.containsKey('identifier') && data['identifier'] is List<int>) {
      return data['identifier'] as List<int>;
    }
    for (final value in data.values) {
      if (value is Map) {
        // Check if it's specifically a Map<String, dynamic>
        if (value.keys.every((k) => k is String)) {
          final nestedIdentifier =
              _findIdentifier(value.cast<String, dynamic>());
          if (nestedIdentifier != null) {
            return nestedIdentifier;
          }
        }
      }
    }
    return null;
  }
}
