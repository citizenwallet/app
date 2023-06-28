import 'dart:convert';
import 'dart:typed_data';

class SignedRequest {
  final Uint8List data;
  final String encoding = 'base64';

  SignedRequest(this.data);

  // map to json
  Map<String, dynamic> toJson() => {
        'data': base64Encode(data),
        'encoding': encoding,
      };
}
