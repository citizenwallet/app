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

QRFormat parseQRFormat(String raw) {
  if (raw.startsWith('ethereum:') && !raw.contains('/')) {
    return QRFormat.eip681;
  } else if (raw.startsWith('ethereum:') && raw.contains('/transfer')) {
    return QRFormat.eip681Transfer;
  } else if (raw.startsWith('0x')) {
    return QRFormat.address;
  } else if (raw.contains('/#/?receiveParams')) {
    return QRFormat.receiveUrl;
  } else if (raw.contains('/#/?voucher')) {
    return QRFormat.voucher;
  } else {
    return QRFormat.unsupported;
  }
}

(String, String?) parseEIP681(String raw) {
  final url = Uri.parse(raw);

  String address = url.pathSegments.first;
  if (address.contains('@')) {
    // includes chain id, remove
    address = address.split('@').first;
  }

  final params = url.queryParameters;

  final value = params['value'];

  return (address, value);
}

(String, String?) parseEIP681Transfer(String raw) {
  final url = Uri.parse(raw);

  final params = url.queryParameters;

  final address = params['address'];
  final value = params['uint256'];

  return (address ?? '', value);
}

(String, String?) parseReceiveUrl(String raw) {
  final receiveUrl = Uri.parse(raw.split('/#/').last);

  final encodedParams = receiveUrl.queryParameters['receiveParams'];
  if (encodedParams == null) {
    return ('', null);
  }

  final decodedParams = decompress(encodedParams);

  final paramUrl = Uri.parse(decodedParams);

  final address = paramUrl.queryParameters['address'];

  final amount = paramUrl.queryParameters['amount'];

  return (address ?? '', amount);
}

(String, String?) parseQRCode(String raw) {
  final format = parseQRFormat(raw);

  switch (format) {
    case QRFormat.address:
      return (raw, null);
    case QRFormat.eip681:
      return parseEIP681(raw);
    case QRFormat.eip681Transfer:
      return parseEIP681Transfer(raw);
    case QRFormat.receiveUrl:
      return parseReceiveUrl(raw);
    case QRFormat.voucher:
    // vouchers are invalid for a transfer
    default:
      return ('', null);
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

String? parseMessageFromReceiveParams(String receiveParams) {
  final receiveUrl = Uri.parse(receiveParams.split('/#/').last);

  final encodedParams = receiveUrl.queryParameters['receiveParams'];
  if (encodedParams == null) {
    return null;
  }

  final decodedParams = decompress(encodedParams);

  final paramUrl = Uri.parse(decodedParams);

  final message = paramUrl.queryParameters['message'];

  return message;
}
