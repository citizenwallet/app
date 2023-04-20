// test if the qr code signature matches the data

import 'dart:convert';

import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  dotenv.load(fileName: '.env');

  group(' QR Wallet', () {
    test('parsing, generation and signing', () async {
      final qr = QR
          .fromCompressedJson(dotenv.get('TEST_COMPRESSED_WALLET_INVALID_SIG'));

      final qrWallet = qr.toQRWallet();

      final signer = Signer.fromQRWallet(
        qrWallet,
        dotenv.get('TEST_WALLET_PASSWORD'),
      );

      await qrWallet.generateSignature(signer);

      final SignatureVerifier verifier = SignatureVerifier(
        data: jsonEncode(qrWallet.raw),
        signature: qrWallet.signature,
        address: qrWallet.data.address,
        publicKey: signer.privateKey.encodedPublicKey,
      );

      final verified = await verifier.verify();

      expect(verified, true);

      final qrSignedWallet = QR
          .fromCompressedJson(dotenv.get('TEST_COMPRESSED_WALLET'))
          .toQRWallet();

      expect(qrSignedWallet.version, 1);
      expect(qrSignedWallet.type, 'qr_wallet');
      expect(qrSignedWallet.raw['address'], dotenv.get('TEST_ADDRESS'));

      expect(await qrSignedWallet.verifyData(), true);

      final compressed = qrSignedWallet.toCompressedJson();

      final decompressed = QR.fromCompressedJson(compressed);

      expect(decompressed.version, 1);
      expect(decompressed.type, 'qr_wallet');
      expect(decompressed.raw['address'], dotenv.get('TEST_ADDRESS'));

      final decompressedQRWallet = decompressed.toQRWallet();

      expect(await decompressedQRWallet.verifyData(), true);
    });
  });
}
