import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/qr.dart';

(String?, String?, String?) deepLinkParamsFromUri(String uri) {
  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

  String? voucherParams = uriData.queryParameters['params'];
  // String? receiveParams = uriData.queryParameters['receiveParams'];
  String? sendToParams;

  if (uriData.queryParameters['sendto'] != null) {
    sendToParams =
        'sendto=${uriData.queryParameters['sendto']}${uriData.queryParameters['amount'] != null ? '&amount=${uriData.queryParameters['amount']}' : ''}${uriData.queryParameters['description'] != null ? '&description=${uriData.queryParameters['description']}' : ''}';
  } else if (uriData.queryParameters['eip681'] != null) {
    sendToParams =
        'eip681=${uriData.queryParameters['eip681']}${uriData.queryParameters['alias'] != null ? '&alias=${uriData.queryParameters['alias']}' : ''}';
  }

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
  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

  return (uriData.queryParameters['voucher'], uriData.queryParameters['dl']);
}

String? aliasFromUri(String uri) {
  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

  return uriData.queryParameters['alias'];
}

String? aliasFromDeepLinkUri(String uri) {
  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

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

  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

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

  final fragment = Uri.parse(uri).fragment;
  
  // Handle the case where fragment starts with /?
  String queryString = fragment;
  if (fragment.startsWith('/?')) {
    queryString = fragment.substring(2);
  }
  
  final uriData = Uri.parse('temp://temp?$queryString');

  switch (format) {
    case QRFormat.sendtoUrl:
      final parsedData = parseSendtoUrl(uriData.toString());
      return parsedData.alias;
    case QRFormat.sendtoUrlWithEIP681:
      // For sendtoUrlWithEIP681, we need to parse the original URI, not the dummy one
      final parsedData = parseSendtoUrlWithEIP681(uri);
      return parsedData.alias;
    default:
      return null;
  }
}
