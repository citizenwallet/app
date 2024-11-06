import 'dart:convert';
import 'dart:math';
import 'package:word_generator/word_generator.dart';

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

String getRandomNoun() {
  final wordGenerator = WordGenerator();
  return wordGenerator.randomNoun();
}

String getRandomUsername() {
  final number = getRandomNumber(len: 4);
  final noun = getRandomNoun();

  return '$noun-$number';
}
