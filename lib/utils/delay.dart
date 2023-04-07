import 'dart:async';

Future<void> delay(Duration d) async {
  await Future.delayed(d);

  return;
}
