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
      final qr = QR.fromJson({
        'version': 1,
        'type': 'qr_wallet',
        'data': {
          'wallet': jsonDecode(dotenv.get('TEST_WALLET')),
          'chainId': 1337,
          'address': dotenv.get('TEST_ADDRESS'),
          'public_key': dotenv.get('TEST_PUBLIC_KEY'),
        },
        'signature': '0x0'
      });

      final qrWallet = qr.toQRWallet();

      expect(await qrWallet.verifyData(), false);

      final signer = Signer.fromWalletFile(
        dotenv.get('TEST_WALLET'),
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

      final qrSignedWallet =
          QR.fromJson(jsonDecode(dotenv.get('TEST_QR_WALLET'))).toQRWallet();

      expect(qrSignedWallet.version, 1);
      expect(qrSignedWallet.type, 'qr_wallet');
      expect(qrSignedWallet.raw['address'], dotenv.get('TEST_ADDRESS'));

      expect(await qrSignedWallet.verifyData(), true);
    });
  });
}
