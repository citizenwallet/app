import 'dart:convert';

Codec<String, String> base64String = utf8.fuse(base64);

Codec<String, String> base64UrlString = utf8.fuse(base64Url);
