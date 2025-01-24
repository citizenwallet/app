import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

String getRandomString(int len) {
  final random = Random.secure();
  final values = List<int>.generate(len, (i) => random.nextInt(255));

  return base64UrlEncode(values);
}

String generateRandomId() {
  final randomId = getRandomString(64);

  final timestamp = DateTime.now().millisecondsSinceEpoch;

  return '$randomId---$timestamp';
}

int getRandomNumber({int len = 6}) {
  final random = Random.secure();
  final values = List<int>.generate(len, (i) => random.nextInt(9));

  return int.parse(values.join());
}

Future<String> getRandomNoun() async {
  final rawNouns =
      jsonDecode(await rootBundle.loadString('assets/words/nouns.json'));

  final nouns = (rawNouns as List).map((e) => e.toString()).toList();

  final random = Random.secure();

  return nouns[random.nextInt(nouns.length)].toLowerCase();
}

Future<String> getRandomUsername() async {
  final number = getRandomNumber(len: 4);
  final noun = await getRandomNoun();

  return '$noun-$number';
}
