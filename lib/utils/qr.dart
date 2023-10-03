import 'package:citizenwallet/services/wallet/utils.dart';

// enum that represents the different qr code formats
enum QRFormat {
  address,
  voucher,
  eip681,
  eip681Transfer,
  receiveUrl,
  unsupported,
}

QRFormat parseQRFormat(String data) {
  if (data.startsWith('ethereum:') && !data.contains('/')) {
    return QRFormat.eip681;
  } else if (data.startsWith('ethereum:') && data.contains('/transfer')) {
    return QRFormat.eip681Transfer;
  } else if (data.startsWith('0x')) {
    return QRFormat.address;
  } else if (data.contains('/#/?receiveParams')) {
    return QRFormat.receiveUrl;
  } else if (data.contains('/#/?voucher')) {
    return QRFormat.voucher;
  } else {
    return QRFormat.unsupported;
  }
}

String? parseAliasFromReceiveParams(String receiveParams) {
  final receiveUrl = Uri.parse(receiveParams.split('/#/').last);

  final encodedParams = receiveUrl.queryParameters['receiveParams'];
  if (encodedParams == null) {
    return null;
  }

  final decodedParams = decompress(encodedParams);

  final paramUrl = Uri.parse(decodedParams);

  final alias = paramUrl.queryParameters['alias'];

  return alias;
}
