const netTimeoutSeconds = 10;
const streamTimeoutSeconds = 10;

const publicKeyHeaderKey = 'x-pubkey';
const signatureKeyHeaderKey = 'x-signature';

class UnauthorizedException implements Exception {
  final String message = 'unauthorized';

  UnauthorizedException();
}

// class SecureRequest {
//   final String secure;

//   SecureRequest(this.secure);

//   SecureRequest.fromJson(Map<String, dynamic> json) : secure = json['secure'];

//   Map<String, dynamic> toJson() => {
//         'secure': secure,
//       };

//   String toEncodedJson() => jsonEncode(toJson());
// }

// class StationRequest {
//   final int version = 1;
//   DateTime expiry = DateTime.now().add(const Duration(seconds: 5)).toUtc();
//   final String address;
//   final String data;

//   StationRequest({
//     required this.address,
//     required this.data,
//   });

//   // from json
//   StationRequest.fromJson(Map<String, dynamic> json)
//       : expiry = DateTime.parse(json['expiry']),
//         address = json['address'],
//         data = base64String.decode(json['data']);

//   // convert to json
//   Map<String, dynamic> toJson() => {
//         'version': version,
//         'expiry': expiry.toIso8601String(),
//         'address': address,
//         'data': base64String.encode(data),
//       };

//   // convert to encoded json
//   String toEncodedJson() => jsonEncode(toJson());
// }

// class VerificationRequest {
//   StationRequest decrypted;
//   String encodedSignature;

//   VerificationRequest({
//     required this.decrypted,
//     required this.encodedSignature,
//   });
// }

// /// [StationService] is a service for interacting with the station api
// ///  - [baseURL] is the base url of the station api
// /// - [address] is the address of the requester
// /// - [requesterKey] is the private key of the requester
// /// - [stationKey] is the public key of the station
// ///
// /// [StationService] is used to:
// /// - get the station key & configuration
// /// - decrypt station requests
// /// - verify station requests
// /// - send station requests
// class StationService {
//   String baseURL;
//   final String address;
//   final EthPrivateKey requesterKey;
//   String? stationKey;

//   StationService({
//     required this.baseURL,
//     required this.address,
//     required this.requesterKey,
//   });

//   String get privateKeyHex => bytesToHex(requesterKey.privateKey);

//   String get publicKeyHex => bytesToHex(requesterKey.encodedPublicKey);

//   void setBaseUrl(String url) {
//     baseURL = url;
//   }

//   String _encryptBody(StationRequest req) {
//     // instantiate the dart ecies library
//     final Ecies ecies = Ecies();

//     // extract the public key in a usable format for the library
//     final SVPublicKey pubkey = SVPublicKey.fromHex(stationKey!);

//     final SVPrivateKey privkey =
//         SVPrivateKey.fromHex(privateKeyHex, NetworkType.TEST);

//     // encode the request data
//     final encoded = utf8.encode(jsonEncode(req));

//     // encrypt the encoded data
//     final encrypted = ecies.AESEncrypt(encoded, privkey, pubkey);

//     // base64 encode the encrypted data
//     final base64Encoded = base64.encode(encrypted);

//     return base64Encoded;
//   }

//   Future<String> encryptBody(StationRequest req) async {
//     return await compute<StationRequest, String>(_encryptBody, req);
//   }

//   /// [_decryptBody] decrypts the body of a station request
//   /// using the receiver's private key
//   ///   - [body] is the base64 encoded body of the request
//   ///
//   /// and returns the decrypted data as a [StationRequest]
//   ///
//   /// with help from:
//   ///  - https://stackoverflow.com/a/75571004/7012894
//   ///  - https://github.com/twostack/dartsv/tree/master
//   StationRequest _decryptBody(String body) {
//     // base64 decode the body
//     final encryptedData = base64.decode(body);

//     // instantiate the dart ecies library
//     final Ecies ecies = Ecies();

//     // extract the private key in a usable format for the library
//     final SVPrivateKey pk = SVPrivateKey.fromBigInt(requesterKey.privateKeyInt);

//     // decrypt the decoded body
//     final decrypted = ecies.AESDecrypt(encryptedData, pk);

//     // decode the decrypted data
//     final decoded = utf8.decode(decrypted);

//     // json decode
//     final json = jsonDecode(decoded);

//     // create a station request from the json
//     final sreq = StationRequest.fromJson(json);

//     // pass the data to the caller
//     return sreq;
//   }

//   Future<StationRequest> decryptBody(String body) async {
//     return await compute<String, StationRequest>(_decryptBody, body);
//   }

//   String _generateSignature(String body) {
//     // hash the body
//     final messageHash = keccak256(convertStringToUint8List(body));

//     // sign the body
//     final signature = sign(messageHash, requesterKey.privateKey);

//     // encode the signature
//     final r = signature.r.toRadixString(16).padLeft(64, '0');
//     final s = signature.s.toRadixString(16).padLeft(64, '0');
//     final v = bytesToHex(intToBytes(BigInt.from(signature.v + 4)));

//     // compact the signature
//     // 0x - padding
//     // v - 1 byte
//     // r - 32 bytes
//     // s - 32 bytes
//     return '0x$v$r$s';
//   }

//   Future<String> generateSignature(String body) async {
//     return await compute<String, String>(_generateSignature, body);
//   }

//   /// [_verifySignature] verifies the signature of the response
//   ///  - [args] is a [VerificationRequest] object
//   ///
//   /// returns a boolean indicating whether the signature is valid
//   Future<bool> _verifySignature(
//     VerificationRequest args,
//   ) async {
//     final StationRequest decrypted = args.decrypted;
//     final String encodedSignature = args.encodedSignature;

//     // check the expiry
//     if (decrypted.expiry.isBefore(DateTime.now())) {
//       return false;
//     }

//     final wpsig = strip0x(encodedSignature);

//     final signature = hexToBytes(encodedSignature);

//     // How to get R & S from signature
//     // https://github.com/simolus3/web3dart/issues/207#issue-1021153710
//     // How to parse R & S so that they don't overflow
//     // https://github.com/c0mm4nd/dart-ecdsa/blob/692b71994ebbd913db22a8cdfc11169d46c2046e/lib/src/signature.dart#L24
//     final msg = MsgSignature(
//       hexToInt(wpsig.substring(2, 66)),
//       hexToInt(wpsig.substring(66, 130)),
//       signature.elementAt(0),
//     );

//     final encodedReq = decrypted.toEncodedJson();

//     final messageHash =
//         keccak256(convertBytesToUint8List(utf8.encode(encodedReq)));

//     final publicKey = ecRecover(messageHash, msg);

//     // the address in the header must match the address derived from the signature
//     final address = bytesToHex(publicKeyToAddress(publicKey), include0x: true);
//     if (address.toLowerCase() != decrypted.address.toLowerCase()) {
//       return false;
//     }

//     // were the contents of the message signed by the sender?
//     final isValid = isValidSignature(messageHash, msg, publicKey);

//     return isValid;
//   }

//   /// [verifySignature] verifies calls the internal [_verifySignature] function on a separate thread
//   /// - [decrypted] is a [StationRequest] object
//   /// - [encodedSignature] is the signature to verify
//   ///
//   /// returns a boolean indicating whether the signature is valid
//   Future<bool> verifySignature(
//     StationRequest decrypted,
//     String encodedSignature,
//   ) async {
//     return await compute<VerificationRequest, bool>(
//       _verifySignature,
//       VerificationRequest(
//         decrypted: decrypted,
//         encodedSignature: encodedSignature,
//       ),
//     );
//   }

//   /// [_get] is a helper function to make a get request to the station api
//   ///   - [route] is the route to make the request to
//   ///
//   /// returns a json decoded response body
//   Future<dynamic> _get({String? route}) async {
//     final pubkey = requesterKey.publicKey.getEncoded(true);

//     final response = await http.get(
//       Uri.parse('$baseURL${route ?? ''}'),
//       headers: <String, String>{
//         'Content-Type': 'application/json; charset=UTF-8',
//         'X-PubKey': bytesToHex(pubkey),
//       },
//     ).timeout(const Duration(seconds: netTimeoutSeconds));

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception('error fetching data');
//     }

//     final body = jsonDecode(response.body);

//     if (body['response_type'] != 'secure') {
//       throw Exception('error invalid response');
//     }

//     final decrypted = await decryptBody(body['secure']);

//     final sig = response.headers[signatureKeyHeaderKey];
//     if (sig == null) {
//       throw Exception('error missing signature');
//     }

//     final headerPubKey = response.headers[publicKeyHeaderKey];
//     if (headerPubKey == null) {
//       throw Exception('error missing send key');
//     }

//     final isVerified = await verifySignature(decrypted, sig);
//     if (!isVerified) {
//       throw Exception('error invalid signature');
//     }

//     stationKey = headerPubKey;

//     return jsonDecode(decrypted.data);
//   }

//   /// [_post] is a helper function to make a post request to the station api
//   ///  - [route] is the route to make the request to
//   /// - [body] is the body of the request
//   ///
//   /// returns a json decoded response body
//   Future<dynamic> _post({
//     String? route,
//     required String body,
//   }) async {
//     // get the public key
//     final pubkey = requesterKey.publicKey.getEncoded(true);

//     // generate the request
//     final StationRequest req = StationRequest(
//       address: requesterKey.address.hexEip55,
//       data: body,
//     );

//     // sign the request
//     final signature = await generateSignature(req.toEncodedJson());

//     // ecrypt it
//     final encryptedBody = await encryptBody(req);

//     final response = await http
//         .post(
//           Uri.parse('$baseURL${route ?? ''}'),
//           headers: <String, String>{
//             'Content-Type': 'application/json; charset=UTF-8',
//             'X-PubKey': bytesToHex(pubkey),
//             'X-Signature': signature,
//           },
//           body: SecureRequest(encryptedBody).toEncodedJson(),
//         )
//         .timeout(const Duration(seconds: netTimeoutSeconds));

//     if (response.statusCode < 200 || response.statusCode >= 300) {
//       throw Exception('error sending data');
//     }

//     return jsonDecode(response.body);
//   }

//   /// [hello] is used to fetch the chain information from the station.
//   /// allows us to receive the station's public key in order to make requests
//   ///
//   /// returns a [Chain] object
//   Future<Chain> hello() async {
//     final response = await _get(route: '/hello');

//     return Chain.fromJson(response);
//   }

//   /// [transaction] is used to send a transaction to the station
//   /// - [body] contains a signed transaction
//   ///
//   /// returns nothing
//   Future<void> transaction(String body) async {
//     final response = await _post(route: '/transaction', body: body);

//     print(response);
//   }
// }
