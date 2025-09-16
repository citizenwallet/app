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

class NetworkException implements Exception {
  final String message = 'network';

  NetworkException();
}

class RPCException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  RPCException({required this.code, required this.message, this.data});

  @override
  String toString() {
    return 'RPCException: [$code] $message${data != null ? ' - $data' : ''}';
  }
}

class APIService {
  final String baseURL;

  final int netTimeoutSeconds;

  APIService({required this.baseURL, this.netTimeoutSeconds = 60});

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
        .timeout(Duration(seconds: netTimeoutSeconds));

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

    if (response.body.isEmpty) {
      return null;
    }

    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> post({
    String? url,
    required Object body,
    Map<String, String>? headers,
    bool isRPC = false,
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
        .timeout(Duration(seconds: netTimeoutSeconds));

    if (isRPC && response.body.contains('"error"')) {
      throw parseRPCError(response.body);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      switch (response.statusCode) {
        case 401:
          throw UnauthorizedException();
        case 404:
          throw NotFoundException();
        case 409:
          throw ConflictException();
      }
      if (isRPC) {
        try {
          throw parseRPCError(response.body);
        } catch (e) {
          if (e is RPCException) rethrow;
        }
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
        .timeout(Duration(seconds: netTimeoutSeconds));

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
        .timeout(Duration(seconds: netTimeoutSeconds));

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
        .timeout(Duration(seconds: netTimeoutSeconds));

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
    ).timeout(Duration(seconds: netTimeoutSeconds));

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

RPCException parseRPCError(String responseBody) {
  try {
    final Map<String, dynamic> errorJson = jsonDecode(responseBody);

    if (errorJson.containsKey('RPCError')) {
      final error = errorJson['error'];
      return RPCException(
        code: error['code'] ?? -1,
        message: error['message'] ?? 'Unknown RPC error',
        data: error['data'],
      );
    }
    return RPCException(code: -1, message: 'Invalid RPC error format');
  } catch (e) {
    return RPCException(code: -1, message: 'Failed to parse RPC error: $e');
  }
}

RPCException parseRPCErrorText(String errorText) {
  try {
    // Pattern to match: RPCError: got code -XXXXX with msg "MESSAGE".
    final RegExp regex =
        RegExp(r'RPCError: got code (-?\d+) with msg "([^"]+)"');
    final match = regex.firstMatch(errorText);

    if (match != null && match.groupCount >= 2) {
      final code = int.parse(match.group(1)!);
      final message = match.group(2)!;

      return RPCException(
        code: code,
        message: message,
        data: null,
      );
    }

    return RPCException(
      code: -1,
      message: 'Could not parse error: $errorText',
      data: null,
    );
  } catch (e) {
    return RPCException(
      code: -1,
      message: 'Failed to parse RPC error text: $e',
      data: null,
    );
  }
}

extension MigrationAPI on APIService {
  Future<bool> checkMigrationRequired() async {
    try {
      final response = await get(url: '/migration');
      
      return false;
    } on NotFoundException {
      return true;
    } catch (e) {
      return false;
    }
  }
}

