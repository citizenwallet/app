import 'dart:convert';

import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/foundation.dart';
import 'package:web3dart/crypto.dart';

const emptyMessage = '';

class MessageAttachment {
  String type;
  String url;

  MessageAttachment({required this.type, required this.url});

  MessageAttachment.image({required this.url}) : type = 'image';

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      type: json['type'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
    };
  }

  @override
  // to string
  String toString() {
    return 'MessageAttachment: $type, $url';
  }
}

class Message {
  final int version = 1;
  final String message;
  final MessageAttachment? attachment;

  Message({this.message = emptyMessage, this.attachment});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'],
      attachment: json['attachment'] != null
          ? MessageAttachment.fromJson(json['attachment'])
          : null,
    );
  }

  factory Message.fromBytes(Uint8List bytes) {
    final json = convertUint8ListToString(bytes);

    return Message.fromJson(jsonDecode(json));
  }

  factory Message.fromHexString(String hex) {
    final bytes = hexToBytes(hex.replaceFirst(hexPadding, ''));

    return Message.fromBytes(bytes);
  }

  Map<String, dynamic> toJson() {
    if (attachment == null) {
      return {
        'version': version,
        'message': message,
      };
    }

    return {
      'version': version,
      'message': message,
      'attachment': attachment!.toJson(),
    };
  }

  Uint8List toBytes() {
    return convertStringToUint8List(jsonEncode(toJson()));
  }

  @override
  // to string
  String toString() {
    return 'Message: $message, Attachment: $attachment';
  }
}
