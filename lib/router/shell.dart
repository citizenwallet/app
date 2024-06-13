import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RouterShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const RouterShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final wallet = context.select((WalletState state) => state.wallet);

    final loading = context.select((WalletState state) => state.loading);
    final cleaningUp = context.select((WalletState state) => state.cleaningUp);

    final transactionSendLoading =
        context.select((WalletState state) => state.transactionSendLoading);

    final imageSmall = context.select((ProfileState state) => state.imageSmall);
    final username = context.select((ProfileState state) => state.username);

    final hasNoProfile = imageSmall == '' && username == '';

    final parts = state.uri.toString().split('/');
    final location = parts.length > 1 ? parts[1] : '/';

    final List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(
        label: AppLocalizations.of(context)!.wallet,
        icon: const Icon(CupertinoIcons.rectangle_on_rectangle_angled),
        activeIcon: const Icon(
          CupertinoIcons.rectangle_on_rectangle_angled,
        ),
      ),
    ];

    final routes = {
      'wallet': 0,
    };

    final app = CupertinoScaffold(
      key: Key(location),
      topRadius: const Radius.circular(40),
      transitionBackgroundColor: Theme.of(context).colors.transparent,
      body: CupertinoPageScaffold(
        key: Key(location),
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
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
                  activeColor:
                      Theme.of(context).colors.text.resolveFrom(context),
                  backgroundColor: Theme.of(context)
                      .colors
                      .uiBackgroundAlt
                      .resolveFrom(context),
                  border: Border(
                      top: BorderSide(
                          color: Theme.of(context)
                              .colors
                              .uiBackgroundAlt
                              .resolveFrom(context),
                          width: 0.0)),
                  onTap: transactionSendLoading || cleaningUp
                      ? null
                      : (index) {
                          switch (index) {
                            case 0:
                              GoRouter.of(context).go(
                                  '/wallet/${wallet?.account}?alias=${wallet?.alias}');
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
            backgroundColor: Theme.of(context).colors.black,
            child: app,
          )
        : app;
  }
}
