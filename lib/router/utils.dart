import 'package:citizenwallet/services/wallet/utils.dart';

(String?, String?, String?) deepLinkParamsFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  String? voucherParams = uriData.queryParameters['params'];
  String? receiveParams = uriData.queryParameters['receiveParams'];
  String? deepLinkParams;
  final deepLink = uriData.queryParameters['dl'];
  if (deepLink != null) {
    final params = uriData.queryParameters[deepLink];
    if (params != null) {
      deepLinkParams = encodeParams(params);
    }
  }

  String? alias;
  if (receiveParams != null) {
    alias = receiveParamsAlias(receiveParams);
  } else {
    alias = aliasFromUri(uri);
  }
  if (alias == null) {
    return (null, null, null);
  }

  print('deepLinkParamsFromUri alias: $alias');

  if (voucherParams != null) {
    voucherParams = '$voucherParams&alias=$alias';
  }

  if (receiveParams != null) {
    receiveParams = '$receiveParams&alias=$alias';
  }

  if (deepLinkParams != null) {
    deepLinkParams = '$deepLinkParams&alias=$alias';
  }

  return (voucherParams, receiveParams, deepLinkParams);
}

(String?, String?) deepLinkContentFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  return (uriData.queryParameters['voucher'], uriData.queryParameters['dl']);
}

String? aliasFromUri(String uri) {
  final uriData = Uri.parse(Uri.parse(uri).fragment);

  return uriData.queryParameters['alias'];
}

String? receiveParamsAlias(String compressedParams) {
  String params;
  try {
    params = decodeParams(compressedParams);
  } catch (_) {
    // support the old format with compressed params
    params = decompress(compressedParams);
  }

  print('receiveParamsAlias params: $params');

  final uri = Uri(query: params);

  return uri.queryParameters['alias'];
}
