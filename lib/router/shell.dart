import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class RouterShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  RouterShell({
    Key? key,
    required this.child,
    required this.state,
  }) : super(key: key);

  final List<BottomNavigationBarItem> items = [
    const BottomNavigationBarItem(
      label: 'Wallet',
      icon: Icon(CupertinoIcons.rectangle_on_rectangle_angled),
      activeIcon: Icon(
        CupertinoIcons.rectangle_on_rectangle_angled,
      ),
    ),
    const BottomNavigationBarItem(
      label: 'Contacts',
      icon: Icon(CupertinoIcons.person_3),
      activeIcon: Icon(
        CupertinoIcons.person_3_fill,
      ),
    ),
    const BottomNavigationBarItem(
      label: 'Settings',
      icon: Icon(CupertinoIcons.settings),
      activeIcon: Icon(
        CupertinoIcons.settings_solid,
      ),
    ),
  ];

  final routes = {
    '/wallet': 0,
    '/contacts': 1,
    '/settings': 2,
  };

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final transactionSendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    final location = state.uri.toString();

    final app = CupertinoScaffold(
      key: Key(location),
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: ThemeColors.transparent,
      body: CupertinoPageScaffold(
        key: Key(location),
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: child,
              ),
              if (!kIsWeb)
                CupertinoTabBar(
                  items: items,
                  currentIndex: routes[location] ?? 0,
                  activeColor: ThemeColors.text.resolveFrom(context),
                  backgroundColor:
                      ThemeColors.uiBackgroundAlt.resolveFrom(context),
                  border: Border(
                      top: BorderSide(
                          color:
                              ThemeColors.uiBackgroundAlt.resolveFrom(context),
                          width: 0.0)),
                  onTap: transactionSendLoading
                      ? null
                      : (index) {
                          switch (index) {
                            case 0:
                              GoRouter.of(context)
                                  .go('/wallet/${wallet?.address}');
                              break;
                            case 1:
                              GoRouter.of(context).go('/contacts');
                              break;
                            case 2:
                              GoRouter.of(context).go('/settings');
                              break;
                            default:
                            // GoRouter.of(context).go('/404');
                          }
                        },
                ),
            ],
          ),
        ),
      ),
    );

    return kIsWeb
        ? CupertinoPageScaffold(
            backgroundColor: ThemeColors.black,
            child: app,
          )
        : app;
  }
}
