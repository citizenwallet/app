import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/cards/screen.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/transaction/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers,
) =>
    GoRouter(
        initialLocation: '/',
        // initialLocation: PreferencesService().firstLaunch ? '/' : '/wallets',
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
              // GoRoute(
              //   name: 'Wallets',
              //   path: '/wallets',
              //   parentNavigatorKey: shellNavigatorKey,
              //   pageBuilder: (context, state) => NoTransitionPage(
              //     key: state.pageKey,
              //     name: state.name,
              //     child: const WalletsScreen(),
              //   ),
              // ),
              GoRoute(
                name: 'Wallet',
                // path: '/wallets',
                path: '/wallet/:chainId/:address',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: WalletScreen(
                      int.tryParse(state.params['chainId'] ?? '0'),
                      state.params['address']),
                ),
                routes: [
                  GoRoute(
                    name: 'Chat',
                    path: 'transactions/:transactionId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => TransactionScreen(
                      transactionId: state.params['transactionId'],
                    ),
                  ),
                ],
              ),
              GoRoute(
                name: 'Cards',
                path: '/cards',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: const CardsScreen(),
                ),
              ),
              GoRoute(
                name: 'Settings',
                path: '/settings',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: const SettingsScreen(),
                ),
              ),
            ],
          ),
        ]);
