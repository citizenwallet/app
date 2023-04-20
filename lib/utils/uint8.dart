import 'package:flutter/foundation.dart';

Uint8List convertStringToUint8List(String str) {
  final List<int> codeUnits = str.codeUnits;
  return Uint8List.fromList(codeUnits);
}

String convertUint8ListToString(Uint8List uint8list) {
  return String.fromCharCodes(uint8list);
}

Uint8List convertBytesToUint8List(List<int> bytes) {
  return Uint8List.fromList(bytes);
}
