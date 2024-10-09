class Log {
  final String hash;
  final String txHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int nonce;
  final String sender;
  final String to;
  final BigInt value;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? extraData;
  final LogStatus status;

  Log({
    required this.hash,
    required this.txHash,
    required this.createdAt,
    required this.updatedAt,
    required this.nonce,
    required this.sender,
    required this.to,
    required this.value,
    this.data,
    this.extraData,
    required this.status,
  });

  factory Log.fromJson(Map<String, dynamic> json) {
    return Log(
      hash: json['hash'],
      txHash: json['tx_hash'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      nonce: json['nonce'],
      sender: json['sender'],
      to: json['to'],
      value: BigInt.from(json['value']),
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
      extraData: json['extra_data'] != null
          ? Map<String, dynamic>.from(json['extra_data'])
          : null,
      status: LogStatus.values
          .firstWhere((e) => e.toString().split('.').last == json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'tx_hash': txHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'nonce': nonce,
      'sender': sender,
      'to': to,
      'value': value.toString(),
      'data': data,
      'extra_data': extraData,
      'status': status.toString().split('.').last,
    };
  }
}

enum LogStatus {
  sending,
  pending,
  success,
  fail,
}

String buildQueryParams(List<Map<String, String>> data,
    {List<Map<String, String>>? or}) {
  final queryParams = <String>[];

  for (final item in data) {
    queryParams
        .add('data.${item['key']}=${Uri.encodeComponent(item['value']!)}');
  }

  if (or != null) {
    for (final item in or) {
      queryParams
          .add('data2.${item['key']}=${Uri.encodeComponent(item['value']!)}');
    }
  }

  return queryParams.join('&');
}
