import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/about/screen.dart';
import 'package:citizenwallet/screens/account/screen.dart';
import 'package:citizenwallet/screens/accounts/screen.android.dart';
import 'package:citizenwallet/screens/accounts/screen.apple.dart';
import 'package:citizenwallet/screens/contacts/screen.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/landing/screen.web.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/transaction/screen.dart';
import 'package:citizenwallet/screens/vouchers/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.web.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers,
  WalletLogic wallet,
) =>
    GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      navigatorKey: rootNavigatorKey,
      observers: observers,
      routes: [
        GoRoute(
          name: 'Landing',
          path: '/',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const LandingScreen(),
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => RouterShell(
            state: state,
            child: child,
          ),
          routes: [
            GoRoute(
              name: 'Wallet',
              path: '/wallet/:address',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                name: state.name,
                child: WalletScreen(
                  state.pathParameters['address'],
                  wallet,
                ),
              ),
              routes: [
                GoRoute(
                  name: 'Transaction',
                  path: 'transactions/:transactionId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    if (state.extra == null) {
                      return const SizedBox();
                    }

                    final extra = state.extra as Map<String, dynamic>;

                    return TransactionScreen(
                      transactionId: state.pathParameters['transactionId'],
                      logic: extra['logic'],
                      profilesLogic: extra['profilesLogic'],
                    );
                  },
                ),
              ],
            ),
            GoRoute(
              name: 'Vouchers',
              path: '/vouchers',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                name: state.name,
                child: const VouchersScreen(),
              ),
            ),
            GoRoute(
              name: 'Contacts',
              path: '/contacts',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                name: state.name,
                child: const ContactsScreen(),
              ),
            ),
            GoRoute(
              name: 'Account',
              path: '/account/:address',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                name: state.name,
                child: AccountScreen(
                  address: state.pathParameters['address'],
                  wallet: wallet,
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          name: 'Settings',
          path: '/settings',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => SettingsScreen(),
        ),
        GoRoute(
          name: 'About',
          path: '/about',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          name: 'Backup',
          path: '/backup',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => isPlatformAndroid()
              ? const AndroidAccountsScreen()
              : const AppleAccountsScreen(),
        ),
      ],
    );

GoRouter createWebRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers,
  WalletLogic wallet,
) =>
    GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: kDebugMode,
      navigatorKey: rootNavigatorKey,
      observers: observers,
      routes: [
        GoRoute(
          name: 'Landing',
          path: '/',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const WebLandingScreen(),
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) => RouterShell(
            state: state,
            child: child,
          ),
          routes: [
            GoRoute(
              name: 'Wallet',
              path: '/wallet/:qr',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) {
                print(state.uri.queryParameters);
                print(state.uri.toString());
                print(Uri.base.host);
                String alias = Uri.base.host.split('.').first;
                if (Uri.base.host.split('.').length >= 4) {
                  alias += '.${Uri.base.host.split('.')[1]}';
                }

                return NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: WillPopScope(
                    onWillPop: () async => false,
                    child: BurnerWalletScreen(
                      state.pathParameters['qr'] ?? '',
                      wallet,
                      alias: alias,
                    ),
                  ),
                );
              },
              routes: [
                GoRoute(
                  name: 'Transaction',
                  path: 'transactions/:transactionId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    if (state.extra == null) {
                      return const SizedBox();
                    }

                    final extra = state.extra as Map<String, dynamic>;

                    return WillPopScope(
                      onWillPop: () async => false,
                      child: TransactionScreen(
                        transactionId: state.pathParameters['transactionId'],
                        logic: extra['logic'],
                        profilesLogic: extra['profilesLogic'],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
