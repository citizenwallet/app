import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

const netTimeoutSeconds = 60;
const streamTimeoutSeconds = 10;

class UnauthorizedException implements Exception {
  final String message = 'unauthorized';

  UnauthorizedException();
}

class NotFoundException implements Exception {
  final String message = 'not found';

  NotFoundException();
}

class ConflictException implements Exception {
  final String message = 'conflict';

  ConflictException();
}

class APIService {
  final String baseURL;

  APIService({required this.baseURL});

  Future<dynamic> get({String? url, Map<String, String>? headers}) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final response = await http
        .get(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: mergedHeaders,
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> post({
    String? url,
    required Object body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final response = await http
        .post(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> patch({
    String? url,
    required Object body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final response = await http
        .patch(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> put({
    String? url,
    required Object body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final response = await http
        .put(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> delete({
    String? url,
    required Object body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final response = await http
        .delete(
          Uri.parse('$baseURL${url ?? ''}'),
          headers: mergedHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> filePut({
    String? url,
    required List<int> file,
    required String fileType,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      // 'Content-Type': 'application/json; charset=UTF-8',
    };
    if (headers != null) {
      mergedHeaders.addAll(headers);
    }

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('$baseURL${url ?? ''}'),
    );

    request.headers.addAll(mergedHeaders);

    final httpImage = http.MultipartFile.fromBytes(
      'file',
      file,
      filename: 'image.$fileType',
    );
    request.files.add(httpImage);

    if (body != null) request.fields['body'] = jsonEncode(body);

    final response = await http.Response.fromStream(
      await request.send(),
    ).timeout(const Duration(seconds: netTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      throw Exception('[${response.statusCode}] ${response.reasonPhrase}');
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
