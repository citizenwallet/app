const List<String> emptyParams = [];

class JSONRPCRequest {
  final String version = '2.0';
  // String id = generateRandomId();
  int id = 1;
  final String method;
  final List<dynamic> params;

  JSONRPCRequest({required this.method, this.params = emptyParams});

  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': version,
      'id': id,
      'method': method,
      'params': params,
    };
  }
}

class SUJSONRPCRequest {
  final String version = '2.0';
  int id = 1;
  final String method;
  final List<dynamic> params;

  SUJSONRPCRequest({required this.method, this.params = emptyParams});

  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': version,
      'id': id,
      'method': method,
      'params': params,
    };
  }
}

class JSONRPCError {
  final int code;
  final String message;
  final dynamic data;

  JSONRPCError({
    required this.code,
    required this.message,
    required this.data,
  });

  factory JSONRPCError.fromJson(Map<String, dynamic> json) {
    return JSONRPCError(
      code: json['code'],
      message: json['message'],
      data: json['data'],
    );
  }
}

class JSONRPCResponse {
  final String version;
  // final String id;
  final int id;
  final dynamic result;
  final JSONRPCError? error;

  JSONRPCResponse({
    required this.version,
    required this.id,
    required this.result,
    this.error,
  });

  factory JSONRPCResponse.fromJson(Map<String, dynamic> json) {
    return JSONRPCResponse(
      version: json['jsonrpc'],
      id: json['id'],
      result: json['result'],
      error:
          json['error'] != null ? JSONRPCError.fromJson(json['error']) : null,
    );
  }
}

class SUJSONRPCResponse {
  final String version;
  final int id;
  final dynamic result;
  final JSONRPCError? error;

  SUJSONRPCResponse({
    required this.version,
    required this.id,
    required this.result,
    this.error,
  });

  factory SUJSONRPCResponse.fromJson(Map<String, dynamic> json) {
    return SUJSONRPCResponse(
      version: json['jsonrpc'],
      id: json['id'],
      result: json['result'],
      error:
          json['error'] != null ? JSONRPCError.fromJson(json['error']) : null,
    );
  }
}
