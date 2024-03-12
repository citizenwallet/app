import 'package:flutter/cupertino.dart';

class AuthMetadata {
  final int id;
  final String name;
  final String description;
  final String url;
  final List<String> icons;

  AuthMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.icons,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'url': url,
      'icons': icons,
    };
  }
}

enum ConnectStatus {
  connected,
  disconnected,
  connecting,
  disconnecting,
  error,
}

class ConnectState with ChangeNotifier {
  bool ready = false;

  ConnectStatus status = ConnectStatus.disconnected;

  AuthMetadata? metadata;

  String? response;

  void setReady(bool ready) {
    this.ready = ready;
    notifyListeners();
  }

  void setStatus(ConnectStatus status) {
    this.status = status;
    notifyListeners();
  }

  void setMetadata(AuthMetadata metadata) {
    this.metadata = metadata;
    notifyListeners();
  }
}
