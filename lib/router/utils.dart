import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/qr.dart';

(String?, String?, String?) deepLinkParamsFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  String? voucherParams = uriData.queryParameters['params'];
  // String? receiveParams = uriData.queryParameters['receiveParams'];
  String? sendToParams = uriData.queryParameters['sendto'] != null
      ? 'sendto=${uriData.queryParameters['sendto']}${uriData.queryParameters['amount'] != null ? '&amount=${uriData.queryParameters['amount']}' : ''}${uriData.queryParameters['description'] != null ? '&description=${uriData.queryParameters['description']}' : ''}'
      : null;
  String? deepLinkParams;
  final deepLink = uriData.queryParameters['dl'];
  if (deepLink != null) {
    final params = uriData.queryParameters[deepLink];
    if (params != null) {
      deepLinkParams = encodeParams(params);
    }
  }

  return (voucherParams, sendToParams, deepLinkParams);
}

(String?, String?) deepLinkContentFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  return (uriData.queryParameters['voucher'], uriData.queryParameters['dl']);
}

String? aliasFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  return uriData.queryParameters['alias'];
}

String? aliasFromDeepLinkUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  final deepLinkName = uriData.queryParameters['dl'];
  if (deepLinkName == null) {
    return null;
  }
  final deepLinkParams = uriData.queryParameters[deepLinkName];
  if (deepLinkParams == null) {
    return null;
  }

  final decodedParams = decodeParams(deepLinkParams);

  final parsedUri = Uri.parse('/?$decodedParams');

  return parsedUri.queryParameters['alias'];
}

String? aliasFromReceiveUri(String uri) {
  final format = parseQRFormat(uri);
  if (format != QRFormat.receiveUrl) {
    return null;
  }

  final uriData = Uri.parse(Uri.parse(uri).fragment);

  final compressedParams = uriData.queryParameters['receiveParams'];
  if (compressedParams == null) {
    return null;
  }

  final String decodedParams = decompress(compressedParams);

  final decodedUri = Uri.parse(decodedParams);

  return decodedUri.queryParameters['alias'];
}

String? aliasFromSendUri(String uri) {
  final format = parseQRFormat(uri);
  if (format != QRFormat.sendtoUrl && format != QRFormat.sendtoUrlWithEIP681) {
    return null;
  }

  final uriData = Uri.parse(Uri.parse(uri).fragment);

  switch (format) {
    case QRFormat.sendtoUrl:
      final parsedData = parseSendtoUrl(uriData.toString());
      return parsedData.alias;
    case QRFormat.sendtoUrlWithEIP681:
      final parsedData = parseSendtoUrlWithEIP681(uriData.toString());
      return parsedData.alias;
    default:
      return null;
  }
}
