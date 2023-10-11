import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:web3dart/credentials.dart';
import 'package:web3dart/crypto.dart';

class MifareData {
  final int mifareFamily;
  final List<int> identifier;

  MifareData({
    required this.mifareFamily,
    required this.identifier,
  });

  // from map
  factory MifareData.fromMap(Map<String, dynamic> map) {
    return MifareData(
      mifareFamily: map['mifareFamily'],
      identifier: map['identifier'],
    );
  }
}

class MiFareCard {
  final MifareData mifare;

  MiFareCard({
    required this.mifare,
  });

  // from map
  factory MiFareCard.fromMap(Map<String, dynamic> map) {
    return MiFareCard(
      mifare: MifareData(
        mifareFamily: map['mifare']['mifareFamily'],
        identifier: map['mifare']['identifier'],
      ),
    );
  }
}

class NFCCard {
  static const int version = 1;

  final String uid;
  final String account;
  String signature = '';

  NFCCard({
    required this.uid,
    required this.account,
    this.signature = '',
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'version': version,
      'account': account,
      'signature': signature,
    };
  }

  // from map
  factory NFCCard.fromMap(Map<String, dynamic> map) {
    if (map['version'] != version) {
      throw Exception(
          'Invalid card version ${map['version']}, expected $version.');
    }

    return NFCCard(
      uid: map['uid'],
      account: map['account'],
      signature: map['signature'],
    );
  }

  // to json
  String toJson() => json.encode(toMap());

  // from json
  factory NFCCard.fromJson(String source) =>
      NFCCard.fromMap(json.decode(source));

  void addSignature(String signature) {
    this.signature = signature;
  }
}

class NFCService {
  static final NFCService _instance = NFCService._internal();

  factory NFCService() {
    return _instance;
  }

  NFCService._internal();

  final origin = dotenv.get('ORIGIN_HEADER');

  Future<bool> get isAvailable => NfcManager.instance.isAvailable();

  Future<NFCCard?> readCard() async {
    Completer<Uri?> completedUri = Completer<Uri?>();

    await NfcManager.instance.startSession(
      alertMessage: 'Place your card on the phone.',
      onError: (error) async {
        completedUri.complete(null);
      },
      onDiscovered: (NfcTag tag) async {
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null) {
          completedUri.complete(null);
          return;
        }

        Uri? parsedUri;

        final message = await ndef.read();
        for (NdefRecord record in message.records) {
          final format = record.typeNameFormat;
          if (!(format == NdefTypeNameFormat.nfcWellknown &&
              record.type.length == 1 &&
              record.type.first == 0x55)) {
            continue;
          }

          final prefix = NdefRecord.URI_PREFIX_LIST[record.payload.first];
          final bodyBytes = record.payload.sublist(1);

          parsedUri = Uri.parse(prefix + utf8.decode(bodyBytes));

          break;
        }

        if (parsedUri == null) {
          return;
        }

        await NfcManager.instance.stopSession(
          alertMessage: 'Card read successfully.',
        );

        completedUri.complete(parsedUri);
      },
    );

    final uri = await completedUri.future;

    if (uri == null) {
      NfcManager.instance.stopSession(
        errorMessage: 'Invalid card.',
      );
      return null;
    }

    if (uri.fragment.isEmpty) {
      NfcManager.instance.stopSession(
        errorMessage: 'Invalid card.',
      );
      return null;
    }

    final parsedFragment = Uri.parse(uri.fragment);

    final compressedCard = parsedFragment.queryParameters['card'];
    if (compressedCard == null) {
      NfcManager.instance.stopSession(
        errorMessage: 'Invalid card.',
      );
      return null;
    }

    final card = NFCCard.fromJson(decompress(compressedCard));

    return card;
  }

  Future<bool> configureCard(EthPrivateKey credentials, String account) async {
    Completer<bool> completedSuccess = Completer<bool>();

    await NfcManager.instance.startSession(
      alertMessage: 'Place your card on the phone.',
      onError: (error) async {
        completedSuccess.complete(false);
      },
      onDiscovered: (NfcTag tag) async {
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null) {
          completedSuccess.complete(false);
          return;
        }

        // check max size
        // TODO: determine what the max size is after we implement the format

        // check if writable
        if (!ndef.isWritable) {
          completedSuccess.complete(false);
          return;
        }

        // check if formatted
        if (tag.data.values.isNotEmpty) {
          // tag.data..clear();
        }

        // if (message.records.isNotEmpty) {
        //   await ndef.write(
        //     NdefMessage([
        //       NdefRecord.createUri(Uri.parse('https://citizenwallet.xyz')),
        //     ]),
        //   );
        // }

        final mifareCard = MiFareCard.fromMap(tag.data);
        if (mifareCard.mifare.mifareFamily != 2 ||
            mifareCard.mifare.identifier.isEmpty) {
          completedSuccess.complete(false);
          return;
        }

        final card = NFCCard(
          uid: bytesToHex(
            Uint8List.fromList(mifareCard.mifare.identifier),
            include0x: true,
          ),
          account: account,
        );

        final signature = credentials.signPersonalMessageToUint8List(
            Uint8List.fromList(card.toJson().codeUnits));

        card.addSignature(bytesToHex(signature, include0x: true));

        await ndef.write(
          NdefMessage([
            NdefRecord.createUri(
                Uri.parse('$origin/#/?card=${compress(card.toJson())}')),
          ]),
        );

        await NfcManager.instance.stopSession(
          alertMessage: 'Card ready.',
        );

        completedSuccess.complete(true);
      },
    );

    final success = await completedSuccess.future;

    if (!success) {
      NfcManager.instance.stopSession(
        errorMessage: 'Invalid card.',
      );
    }

    return success;
  }
}
