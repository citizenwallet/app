import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';

class AndroidBackupScreen extends StatelessWidget {
  const AndroidBackupScreen({Key? key}) : super(key: key);

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
                      SizedBox(height: 60 + safePadding),
                      Text(
                        "Backups use Android Auto Backup and follow your device's backup settings automatically.",
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'If you install the app again on another device which shares the same Google account, the encrypted backup will be used to restore your accounts.',
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
