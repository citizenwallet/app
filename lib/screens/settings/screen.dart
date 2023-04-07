import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  final String title = 'Settings';

  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
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
