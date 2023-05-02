import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/web3dart.dart';

BigInt parseIntFromHex(String hex) {
  return BigInt.parse(hex);
}

const zeroHexValue = '0x0';
const hexPadding = '0x';

bool isZeroHexValue(String hex) {
  return hex == zeroHexValue || hex == hexPadding;
}

String formatHexAddress(String address) {
  if (isZeroHexValue(address)) {
    return address;
  }

  final first = address.substring(0, 6);
  final last = address.substring(address.length - 4, address.length);

  return '$first...$last';
}

bool isHexValue(String hex) {
  return hex.startsWith(hexPadding);
}

EthPrivateKey? stringToPrivateKey(String privateKey) {
  try {
    final String formattedPrivateKey = privateKey.startsWith(hexPadding)
        ? privateKey
        : '$hexPadding$privateKey';

    return EthPrivateKey.fromHex(formattedPrivateKey);
  } catch (e) {
    return null;
  }
}

bool isValidPrivateKey(String privateKey) {
  try {
    final String formattedPrivateKey = privateKey.startsWith(hexPadding)
        ? privateKey
        : '$hexPadding$privateKey';

    EthPrivateKey.fromHex(formattedPrivateKey);
    return true;
  } catch (e) {
    return false;
  }
}

String compress(String data) {
  final enCodedData = utf8.encode(data);
  final gZipData = GZipEncoder().encode(enCodedData, level: 6);
  return base64Url.encode(gZipData!);
}

Uint8List compressBytes(Uint8List data) {
  final gZipData = GZipEncoder().encode(data, level: 6);
  return convertBytesToUint8List(gZipData!);
}

String decompress(String data) {
  final decodeBase64Data = base64Url.decode(data);
  final decodegZipData = GZipDecoder().decodeBytes(decodeBase64Data);
  return utf8.decode(decodegZipData);
}

Uint8List decompressBytes(Uint8List data) {
  final decodegZipData = GZipDecoder().decodeBytes(data);
  return convertBytesToUint8List(decodegZipData);
}
