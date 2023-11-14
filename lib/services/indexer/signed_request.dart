import 'dart:convert';
import 'dart:typed_data';

class SignedRequest {
  final Uint8List data;
  final String encoding = 'base64';
  final int expiry = DateTime.now()
      .add(const Duration(seconds: 30))
      .toUtc()
      .millisecondsSinceEpoch;
  final int version = 3;

  SignedRequest(this.data);

  // map to json
  Map<String, dynamic> toJson() => {
        'data': base64Encode(data),
        'encoding': encoding,
        'expiry': expiry,
        'version': version,
      };
}
