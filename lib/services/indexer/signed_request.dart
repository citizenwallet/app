import 'dart:convert';
import 'dart:typed_data';

class SignedRequest {
  final Uint8List data;
  final String encoding = 'base64';
  final int expiry = DateTime.now()
      .add(const Duration(seconds: 30))
      .toUtc()
      .millisecondsSinceEpoch;
  final int version;

  SignedRequest(this.data) : version = 3;
  SignedRequest.v2(this.data) : version = 2;

  // map to json
  Map<String, dynamic> toJson() => {
        'data': base64Encode(data),
        'encoding': encoding,
        'expiry': expiry,
        'version': version,
      };
}
