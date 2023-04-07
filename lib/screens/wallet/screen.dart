import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';

class WalletScreen extends StatefulWidget {
  final String title = 'Wallet';

  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: widget.title,
            actionButton: CupertinoButton(
              onPressed: () => print('hello'),
              child: const Icon(
                CupertinoIcons.settings,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
