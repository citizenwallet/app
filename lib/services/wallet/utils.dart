import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

EtherAmount toEtherAmount(BigInt amount, {int decimals = 6}) {
  EtherUnit unit = switch (decimals) {
    0 => EtherUnit.wei,
    3 => EtherUnit.wei,
    6 => EtherUnit.kwei,
    9 => EtherUnit.mwei,
    12 => EtherUnit.gwei,
    15 => EtherUnit.szabo,
    18 => EtherUnit.finney,
    _ => EtherUnit.wei,
  };
  return EtherAmount.fromBigInt(unit, amount);
}

BigInt toWeiUnit(BigInt amount, {int decimals = 6}) {
  EtherUnit unit = switch (decimals) {
    0 => EtherUnit.wei,
    3 => EtherUnit.wei,
    6 => EtherUnit.kwei,
    9 => EtherUnit.mwei,
    12 => EtherUnit.gwei,
    15 => EtherUnit.szabo,
    18 => EtherUnit.finney,
    _ => EtherUnit.wei,
  };
  return EtherAmount.fromBigInt(unit, amount).getInWei;
}

/// toUnit takes a user readable amount and converts it to a BigInt
BigInt toUnit(String amount, {int decimals = 6}) {
  final exponent = decimals;
  return BigInt.from(double.parse(amount) *
      BigInt.from(10).pow(exponent < 0 ? 0 : exponent).toDouble());
}

/// fromUnit takes a BigInt and converts it into a user readable amount
String fromUnit(BigInt amount, {int decimals = 6}) {
  final pow = decimals;
  return BigInt.from(amount / BigInt.from(10).pow(pow < 0 ? 0 : pow))
      .toString();
}

String fromDoubleUnit(String amount, {int decimals = 6}) {
  final exponent = decimals;
  return (double.parse(amount) / pow(10.0, exponent < 0 ? 0 : exponent))
      .toStringAsFixed(2);
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

Uint8List hashSignatureData(Uint8List payload) {
  const messagePrefix = '\u0019Ethereum Signed Message:\n';

  final prefix = messagePrefix + payload.length.toString();
  final prefixBytes = ascii.encode(prefix);

  return keccak256(Uint8List.fromList(prefixBytes + payload));
}

// parseSignature parses a signature string into its components (r, s, v)
MsgSignature parseSignature(Uint8List signature) {
  final r = bytesToInt(signature.sublist(0, 32));
  final s = bytesToInt(signature.sublist(32, 64));
  final v = bytesToInt(signature.sublist(64, 65));

  return MsgSignature(r, s, v.toInt());
}

EthereumAddress recoverAddressFromPersonalSignature(
    Uint8List originalData, Uint8List signature) {
  final hashedPayload = hashSignatureData(originalData);

  final pubKey = ecRecover(hashedPayload, parseSignature(signature));

  return EthereumAddress.fromPublicKey(pubKey);
}
