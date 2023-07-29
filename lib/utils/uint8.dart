import 'package:flutter/foundation.dart';

Uint8List convertStringToUint8List(String str, {int? forcePadLength}) {
  final List<int> codeUnits =
      (forcePadLength == null ? str : str.padLeft(forcePadLength)).codeUnits;
  return Uint8List.fromList(codeUnits);
}

List<int> convertStringToListInt(String str) {
  final List<int> codeUnits = str.codeUnits;
  return codeUnits;
}

String convertUint8ListToString(Uint8List uint8list) {
  return String.fromCharCodes(uint8list);
}

String convertLinstInListToString(List<int> uint8list) {
  return String.fromCharCodes(uint8list);
}

Uint8List convertBytesToUint8List(List<int> bytes) {
  return Uint8List.fromList(bytes);
}

List<int> convertUint8ListToBytes(Uint8List bytes) {
  return bytes.toList();
}
