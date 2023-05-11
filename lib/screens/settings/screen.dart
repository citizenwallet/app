import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/settings_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  final String title = 'Settings';

  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  late AppLogic _appLogic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      _appLogic = AppLogic(context);
    });
  }

  void onChanged(bool enabled) {
    _appLogic.setDarkMode(enabled);
    HapticFeedback.mediumImpact();
  }

  void handleAppReset() {
    print('reset');
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = context.select((AppState state) => state.darkMode);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Flex(
        direction: Axis.vertical,
        children: [
          Header(
            title: widget.title,
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                  child: Text(
                    'App',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SettingsRow(
                  label: 'Dark mode',
                  trailing: CupertinoSwitch(
                    value: darkMode,
                    onChanged: onChanged,
                  ),
                ),
                // const Padding(
                //   padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
                //   child: Text(
                //     'Wallet',
                //     style: TextStyle(
                //       fontSize: 22,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
                // const SettingsRow(
                //   label: 'Setting 1',
                //   trailing: Text('Property 1'),
                // ),
                // const SettingsRow(
                //   label: 'Setting 2',
                //   trailing: Text('Property 2'),
                // ),
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                //   child: Button(
                //     text: 'Clear App Data',
                //     color: CupertinoColors.systemRed,
                //     onPressed: handleAppReset,
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
