import 'package:nfc_manager/nfc_manager.dart';

class NFCService {
  static final NFCService _instance = NFCService._internal();

  factory NFCService() {
    return _instance;
  }

  NFCService._internal();

  Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  void read() async {
    print('Reading NFC tag...');
    print('NFC available: $isAvailable');

    NfcManager.instance.startSession(
        alertMessage: 'hello there',
        onDiscovered: (NfcTag tag) async {
          print('discovered');
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            print('Tag is not compatible with NDEF');
            return;
          }

          final message = await ndef.read();
          for (NdefRecord record in message.records) {
            print(
                'Discovered ${record.type.toString()} ${record.identifier.toString()} ${record.payload.toString()}');
          }
        });
  }
}
