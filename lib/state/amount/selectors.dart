import 'package:citizenwallet/state/amount/state.dart';

String selectFormattedAmount(AmountState state) {
  final pressedKeys = state.pressedKeys;

  return pressedKeys.asMap().entries.map((entry) {
    final v = entry.value;
    final i = entry.key;
    if (i == pressedKeys.length - 3) {
      return '$v.';
    }

    return v;
  }).join('');
}
