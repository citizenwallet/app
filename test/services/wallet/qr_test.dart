// test if the qr code parsing

import 'package:citizenwallet/utils/qr.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> cases = [
  'https://app.citizenwallet.xyz/#/?receiveParams=H4sIAO8gHGUA_7NPTEkpSi0utjWocHG0TDU2dDM0N3MzdTKxtEwydjIysEg0MnBLNTQD8hIdDQydHI3M1BJzMhOLbRMLCgC_bpezPQAAAA==',
  'https://app.citizenwallet.xyz/#/?receiveParams=H4sIABYhHGUA_w3MQQqAIBAAwN94jF0ty8MSSviPDZcIsiQLen4e5zIzp3RLrQTf4p0YjDjaOITeudUEDRNriIK2iT1g8NoqPnauxKUoztd7PoQdgMpt4U3oBzYQnutSAAAA',
  'https://app.citizenwallet.xyz/#/?voucher=H4sIAOQjHGUA_0WQ22rDMAyG38XXCchWfFDeRgebhbZbSELZKH33Od3Gbmws9Evf54fT7Ws9Ptz8cLqsb3Vzs-O6jz6UUY_NDb_llTe-7Wfbcu8tVSMZMlVFDUlIARkM25RbK5jEPf-CR_08zkCOmVAkiYlB8DEwc21Zp8mslsZqFENoqWUpMWG1bFJIBapaMOsgF2t90P4C_nn-Q9nlWt_djGFw_epn9yiDW93sB7fz9UQwyJQYGvqUoAIF7TuzTcghhA5eofhsuWN0Ou99Y08QRTlDgO55Ot1Y-yRfkRJFJaEkGHPARqIwCVUuBXNNhRqUbERaEmhSsDilXmnIWV6_s9iJJD1rAqMnpnHyDUeKPI1oUdkLYG6n-b1u-_Jx-j2_ASd26ZKxAQAA&params=H4sIAOQjHGUA_wXBMQqAIBQA0Ks4OYaaficHUbtA1P41o6BSrKDj9x4eO94Ga6WpZXxKM-zTKqKSbrV8gABR-pyClgmYYAss0VtQQupe0AvPbObypi03spZGWMfJNHr3A51CYNJWAAAA&alias=app',
  'https://app.citizenwallet.xyz/#/',
  'https://app.citizenwallet.xyz',
  '0xDA9e31F176F5B499b3B208a20Fe169b3aA01BA26',
  'ethereum:0xDA9e31F176F5B499b3B208a20Fe169b3aA01BA26',
  'ethereum:0xDA9e31F176F5B499b3B208a20Fe169b3aA01BA26?value=0.1&gas=0.1&gasPrice=0.1&data=0x0',
  'ethereum:0x89205a3a3b2a69de6dbf7f01ed13b2108b2c43e7/transfer?address=0xDA9e31F176F5B499b3B208a20Fe169b3aA01BA26&uint256=1',
  '',
  'DA9e31F176F5B499b3B208a20Fe169b3aA01BA26',
];

const List<QRFormat> expected = [
  QRFormat.receiveUrl,
  QRFormat.receiveUrl,
  QRFormat.voucher,
  QRFormat.unsupported,
  QRFormat.unsupported,
  QRFormat.address,
  QRFormat.eip681,
  QRFormat.eip681,
  QRFormat.eip681Transfer,
  QRFormat.unsupported,
  QRFormat.unsupported,
];

void main() {
  dotenv.load(fileName: '.env');

  group('QR code parsing', () {
    test('detect various formats', () async {
      for (int i = 0; i < cases.length; i++) {
        expect(parseQRFormat(cases[i]), expected[i]);
      }
    });
  });
}
