import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/transaction/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.web.dart';
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
                  state.params['address'],
                ),
              ),
              routes: [
                GoRoute(
                  name: 'Transaction',
                  path: 'transactions/:transactionId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => TransactionScreen(
                    address: state.params['address'],
                    transactionId: state.params['transactionId'],
                  ),
                ),
              ],
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
      ],
    );

GoRouter createWebRouter(
  GlobalKey<NavigatorState> rootNavigatorKey,
  GlobalKey<NavigatorState> shellNavigatorKey,
  List<NavigatorObserver> observers,
) =>
    GoRouter(
      // initialLocation: '/',
      initialLocation:
          '/wallet/H4sIAO15SmQA_0VS224cIQz9l3nelYwNGPKYRpH6FREY06yySbYzmzRR1H-vYbftjLjY2MfnGL6Wd123w-vLcuN2y_nzpMvN8nN9-FWORz0vu6WVc1luvparw3ayfp7Or3N3OD3qaglFt73DtJfzaikX96ms5XkbYYd3C4FeOoukHDSIay1nlzJX0CohQITl99_Es35YncW5VGNyQaShz5hajZapDgoxQancRGKF6rRG33ul5qF18A0L9V6yEXlq3YC2Sfhi_ifVno5qogl3iy3JZduYlLRbTrMVWzkOFhmcA68MGpuVceyxeMiaSssSuPdGLCAld4jRVcwgoQXVokl91z5kPRcxJJJgXp_Ep5I0N5aQgCB1jGqIAl0rRnSF0SNHbqGjaBJXfaZWaSAdmgG12gJprfuuDfc-KO5TkbgXNJ6-J8pSTO2_e6XR2cdyePlu2Y6Id0tpbdVtG9fyAZUZ7yN7vYv9NvK3ED3fKvR62_D-VnNwId7ZBVln3urxIA9P-mmZ6lmQ1IXm2OVeI7HnJEQeFUMMlCAEdlCrXU3vpjX2pio9hBKg9OhjB0cgbLeamDhBJ1Nd1DEkIomxBOwWxNX0-hZBoA0QKcraRj-2w4-Xcn5bdSrhisiISMVGJqRE3mZnqxUnsoH2dvL0ewo22GZnI8yzMCMvPm97sjVPa_jIPGM3vjC9A9FkW-Y4s1dpa7YxbG-WqTP_OHFzxsHHPjGedOVJs8qIHbV4Yo91IIerggs20lDlpk1m54k7WOPUNXLSjOGpzV-ZwWTjZqybf5po_lobJ0uauHlWGHa48oyD5zhj6_gfMYIDHC4EAAA=',
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
              path: '/wallet/:qr',
              parentNavigatorKey: shellNavigatorKey,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                name: state.name,
                child: BurnerWalletScreen(
                  state.params['qr'] ?? '',
                ),
              ),
              routes: [
                GoRoute(
                  name: 'Transaction',
                  path: 'transactions/:transactionId',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;

                    return TransactionScreen(
                      qr: state.params['qr'],
                      password: extra['password'],
                      transactionId: state.params['transactionId'],
                    );
                  },
                ),
              ],
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
      ],
    );
