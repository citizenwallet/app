import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/screens/wallets/screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers,
) =>
    GoRouter(
        // initialLocation: '/',
        initialLocation: '/wallet/1',
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
          GoRoute(
            name: 'Wallet',
            path: '/wallet/:id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => RouterShell(
              state: state,
              child: const WalletScreen(),
            ),
          ),
          ShellRoute(
            navigatorKey: shellNavigatorKey,
            builder: (context, state, child) => RouterShell(
              state: state,
              child: child,
            ),
            routes: [
              GoRoute(
                name: 'Wallets',
                path: '/wallets',
                parentNavigatorKey: shellNavigatorKey,
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: const WalletsScreen(),
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
