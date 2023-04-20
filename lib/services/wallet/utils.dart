import 'dart:convert';
import 'dart:io';

BigInt parseIntFromHex(String hex) {
  return BigInt.parse(hex);
}

const zeroHexValue = '0x0';
const hexPadding = '0x';

bool isZeroHexValue(String hex) {
  return hex == zeroHexValue || hex == hexPadding;
}

String compress(String data) {
  final enCodedData = utf8.encode(data);
  final gZipData = gzip.encode(enCodedData);
  return base64.encode(gZipData);
}

String decompress(String data) {
  final decodeBase64Data = base64.decode(data);
  final decodegZipData = gzip.decode(decodeBase64Data);
  return utf8.decode(decodegZipData);
}
