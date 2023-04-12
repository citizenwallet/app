import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

const netTimeoutSeconds = 10;
const streamTimeoutSeconds = 10;

class UnauthorizedException implements Exception {
  final String message = 'unauthorized';

  UnauthorizedException();
}

class APIService {
  final String baseURL;

  APIService({required this.baseURL});

  Future<dynamic> get({String? url}) async {
    final response = await http.get(
      Uri.parse('$baseURL${url ?? ''}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ).timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('error fetching data');
    }

    return jsonDecode(response.body);
  }

  Future<dynamic> post({String? url, required Object body}) async {
    final response = await http
        .post(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('error sending data');
    }

    return jsonDecode(response.body);
  }
}
