import 'package:citizenwallet/state/amount/logic.dart';
import 'package:citizenwallet/state/amount/selectors.dart';
import 'package:citizenwallet/state/amount/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AmountEntry extends StatefulWidget {
  const AmountEntry({super.key});

  @override
  AmountEntryState createState() => AmountEntryState();
}

class AmountEntryState extends State<AmountEntry> {
  late AmountLogic _logic;

  @override
  void initState() {
    super.initState();

    _logic = AmountLogic(context);
  }

  final List<String> keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '0',
    '⌫',
  ];

  bool shouldDisableKey(String key, List<String> pressedKeys) {
    if (pressedKeys.every((k) => k == '0')) {
      return [
        '',
        '0',
        '⌫',
      ].contains(key);
    }

    return false;
  }

  void handleKeyPress(String key) {
    // Handle key press
    if (key == '') {
      return;
    }
    HapticFeedback.lightImpact();
    _logic.keyPress(key);
  }

  void h(int i, String v) {}

  @override
  Widget build(BuildContext context) {
    final config = context.watch<WalletState>().config;
    if (config == null) {
      return const SizedBox();
    }

    final pressedKeys = context.watch<AmountState>().pressedKeys;

    final amount = context.select(selectFormattedAmount);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    amount,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  CoinLogo(
                    size: 32,
                    logo: config.community.logo,
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 16.0,
                    padding: const EdgeInsets.all(16.0),
                    children: keys.map(
                      (key) {
                        final disabled = shouldDisableKey(key, pressedKeys);

                        return CupertinoButton(
                          onPressed: disabled
                              ? null
                              : () {
                                  // Handle button press
                                  handleKeyPress(key);
                                },
                          child: Text(
                            key,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: disabled
                                  ? Theme.of(context)
                                      .colors
                                      .subtleEmphasis
                                      .resolveFrom(context)
                                  : Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
