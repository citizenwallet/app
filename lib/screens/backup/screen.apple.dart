import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';

class AppleBackupScreen extends StatelessWidget {
  const AppleBackupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      Text(
                        "Your accounts are backed up to your iPhone's Keychain and follow your backup settings automatically.",
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Enabling \"Sync this iPhone\" will ensure that your iPhone's keychain gets backed up to iCloud.",
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You can check if syncing is enabled in your Settings app by going to: Apple ID > iCloud > Passwords and Keychain.',
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Your accounts and your account backups are generated and owned by you.",
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "They can be manually exported at any time.",
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Header(
            blur: true,
            transparent: true,
            showBackButton: true,
            title: 'Backup',
            safePadding: safePadding,
          ),
        ],
      ),
    );
  }
}
