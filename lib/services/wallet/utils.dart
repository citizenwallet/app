import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

// final gwei = BigInt.from(10).pow(9);
final ether = BigInt.from(10).pow(18);
// final finney = BigInt.from(10).pow(15);
final finney = BigInt.from(10).pow(3);

BigInt toUnit(String amount) {
  return BigInt.parse(amount) * finney;
}

String fromUnit(BigInt amount) {
  return BigInt.from(amount / finney).toString();
}

BigInt parseIntFromHex(String hex) {
  return BigInt.parse(hex);
}

String bigIntToHex(BigInt value) {
  final hex = value.toRadixString(16);

  return '0x$hex';
}

const zeroHexValue = '0x0';
const hexPadding = '0x';

bool isZeroHexValue(String hex) {
  return hex == zeroHexValue || hex == hexPadding;
}

String formatHexAddress(String address) {
  if (isZeroHexValue(address) || address.length < 6) {
    return address;
  }

  final first = address.substring(0, 6);
  final last = address.substring(address.length - 4, address.length);

  return '$first...$last';
}

bool isHexValue(String hex) {
  return hex.startsWith(hexPadding);
}

bool includesHexValue(String hex) {
  return hex.contains(hexPadding);
}

String extractHexFromText(String text) {
  final hex = RegExp(r'0x[a-fA-F0-9]+').stringMatch(text);

  return hex ?? '';
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

String generateSignature((String body, Uint8List privateKey) args) {
  // hash the body
  final messageHash = keccak256(convertBytesToUint8List(utf8.encode(args.$1)));

  // sign the body
  final signature = sign(messageHash, args.$2);

  // encode the signature
  final r = signature.r.toRadixString(16).padLeft(64, '0');
  final s = signature.s.toRadixString(16).padLeft(64, '0');
  final v = bytesToHex(intToBytes(BigInt.from(signature.v + 4)));

  // compact the signature
  // 0x - padding
  // v - 1 byte
  // r - 32 bytes
  // s - 32 bytes
  return '0x$v$r$s';
}
