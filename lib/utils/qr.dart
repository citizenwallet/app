import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/send.dart';

// enum that represents the different qr code formats
enum QRFormat {
  address,
  voucher,
  eip681,
  eip681Transfer,
  receiveUrl,
  sendtoUrl,
  sendtoUrlWithEIP681,
  url,
  unsupported,
}

QRFormat parseQRFormat(String raw) {
  if (raw.startsWith('ethereum:') && !raw.contains('/')) {
    return QRFormat.eip681;
  } else if (raw.startsWith('ethereum:') && raw.contains('/transfer')) {
    return QRFormat.eip681Transfer;
  } else if (raw.startsWith('https://') && raw.contains('eip681=')) {
    return QRFormat.sendtoUrlWithEIP681;
  } else if (raw.startsWith('http://') && raw.contains('sendto=')) {
    return QRFormat.sendtoUrl;
  } else if (raw.startsWith('https://') && raw.contains('sendto=')) {
    return QRFormat.sendtoUrl;
  } else if (raw.startsWith('0x')) {
    return QRFormat.address;
  } else if (raw.contains('receiveParams=')) {
    return QRFormat.receiveUrl;
  } else if (raw.contains('voucher=')) {
    return QRFormat.voucher;
  } else if (raw.startsWith('https://') || raw.startsWith('http://')) {
    return QRFormat.url;
  } else {
    return QRFormat.unsupported;
  }
}

// address, value, null, null
ParsedQRData parseEIP681(String raw) {
  final url = Uri.parse(raw);

  String address = url.pathSegments.first;
  if (address.contains('@')) {
    // includes chain id, remove
    address = address.split('@').first;
  }

  final params = url.queryParameters;

  final value = params['value'];

  return ParsedQRData(address: address, amount: value);
}

ParsedQRData parseEIP681Transfer(String raw) {
  final url = Uri.parse(raw);

  final params = url.queryParameters;

  final address = params['address'];
  final value = params['uint256'];

  return ParsedQRData(address: address ?? '', amount: value);
}

ParsedQRData parseSendtoUrlWithEIP681(String raw) {
  final cleanRaw = raw.replaceFirst('/#/', '/');

  final receiveUrl = Uri.parse(cleanRaw);

  final urlEncodedParams = receiveUrl.queryParameters['eip681'];

  if (urlEncodedParams == null) {
    return ParsedQRData(address: '');
  }

  // Need to url decode the sendto param
  final decodedEIP681Param = Uri.decodeComponent(urlEncodedParams);
  return parseEIP681(decodedEIP681Param);
}

// parse the sendto url
// raw is the URL from the QR code, eg. https://example.com/?sendto=:username@:communitySlug&amount=100&description=Hello
ParsedQRData parseSendtoUrl(String raw) {
  final cleanRaw = raw.replaceFirst('/#/', '/');
  final decodedRaw = Uri.decodeComponent(cleanRaw);

  final receiveUrl = Uri.parse(decodedRaw);

  final sendToParam = receiveUrl.queryParameters['sendto'];
  final amountParam = receiveUrl.queryParameters['amount'];
  final descriptionParam = receiveUrl.queryParameters['description'];

  final tipToParam = receiveUrl.queryParameters['tipTo'];
  final tipAmountParam = receiveUrl.queryParameters['tipAmount'];
  final tipDescriptionParam = receiveUrl.queryParameters['tipDescription'];

  if (sendToParam == null) {
    return ParsedQRData(address: '');
  }

  final address = sendToParam.split('@').first;
  final alias = sendToParam.split('@').last;

  final tip = tipToParam != null
      ? SendDestination(
          to: tipToParam,
          amount: tipAmountParam,
          description: tipDescriptionParam,
        )
      : null;

  return ParsedQRData(
    address: address,
    amount: amountParam,
    description: descriptionParam,
    alias: alias,
    tip: tip,
  );
}

ParsedQRData parseReceiveUrl(String raw) {
  final receiveUrl = Uri.parse(raw.split('/#/').last);

  final encodedParams = receiveUrl.queryParameters['receiveParams'];
  if (encodedParams != null) {
    final decodedParams = decompress(encodedParams);
    final paramUrl = Uri.parse(decodedParams);
    final address = paramUrl.queryParameters['address'];
    final amount = paramUrl.queryParameters['amount'];
    final alias = paramUrl.queryParameters['alias'];

    return ParsedQRData(
      address: address ?? '',
      amount: amount,
      alias: alias != '' ? alias : null,
    );
  }

  // Handle new format
  final sendToParam = receiveUrl.queryParameters['sendto'];
  if (sendToParam != null) {
    final parts = sendToParam.split('@');
    final address = parts[0];
    final alias = parts.length > 1 ? parts[1] : null;
    final amount = receiveUrl.queryParameters['amount'];
    final description = receiveUrl.queryParameters['description'];

    return ParsedQRData(
      address: address,
      amount: amount,
      description: description,
      alias: alias,
    );
  }

  return ParsedQRData(address: '');
}

// address, amount, description, alias
ParsedQRData parseQRCode(String raw) {
  final format = parseQRFormat(raw);

  switch (format) {
    case QRFormat.address:
      return ParsedQRData(address: raw);
    case QRFormat.eip681:
      return parseEIP681(raw);
    case QRFormat.eip681Transfer:
      return parseEIP681Transfer(raw);
    case QRFormat.receiveUrl:
      return parseReceiveUrl(raw);
    case QRFormat.sendtoUrl:
      return parseSendtoUrl(raw);
    case QRFormat.sendtoUrlWithEIP681:
      return parseSendtoUrlWithEIP681(raw);
    case QRFormat.url:
    // nothing to parse
    case QRFormat.voucher:
    // vouchers are invalid for a transfer
    default:
      return ParsedQRData(address: '');
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

class ParsedQRData {
  final String address;
  final String? amount;
  final String? description;
  final String? alias;
  final SendDestination? tip;

  const ParsedQRData({
    required this.address,
    this.amount,
    this.description,
    this.alias,
    this.tip,
  });
}
