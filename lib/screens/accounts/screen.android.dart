import 'package:citizenwallet/l10n/app_localizations.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AndroidAccountsScreen extends StatelessWidget {
  const AndroidAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding.top;

    return CupertinoPageScaffold(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CustomScrollView(
            scrollBehavior: const CupertinoScrollBehavior(),
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
                        AppLocalizations.of(context)!
                            .accountsAndroidBackupsuseAndroid,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!
                            .accountsAndroidIfYouInstalltheAppAgain,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!
                            .accountsAndroidYouraccounts,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        AppLocalizations.of(context)!
                            .accountsAndroidManuallyExported,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colors
                              .text
                              .resolveFrom(context),
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
            title: AppLocalizations.of(context)!.accounts,
            safePadding: safePadding,
          ),
        ],
      ),
    );
  }
}
