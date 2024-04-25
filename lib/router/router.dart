import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/about/screen.dart';
import 'package:citizenwallet/screens/account/screen.dart';
import 'package:citizenwallet/screens/accounts/screen.android.dart';
import 'package:citizenwallet/screens/accounts/screen.apple.dart';
import 'package:citizenwallet/screens/contacts/screen.dart';
import 'package:citizenwallet/screens/landing/account_connected.dart';
import 'package:citizenwallet/screens/landing/account_recovery.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/landing/screen.web.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/transaction/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.web.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
            builder: (context, state) {
              // coming in from a deep link "#/wallet/..." will come as a fragment
              final uri = Uri.parse(state.uri.fragment);

              // parse from a deep link
              String? deepLinkParams;
              final deepLink = uri.queryParameters['dl'];
              if (deepLink != null) {
                final params = uri.queryParameters[deepLink];
                if (params != null) {
                  deepLinkParams = encodeParams(params);
                }
              }

              // parse from a voucher deep link
              final voucher = uri.queryParameters['voucher'];
              final voucherParams = uri.queryParameters['params'];

              // parse from a wallet deep link
              String? webWallet;
              String? webWalletAlias;

              final fragment = state.uri.fragment;
              if (fragment.contains('/wallet/')) {
                // attempt to parse the compressed wallet json
                webWallet = uri.path.split('/wallet/').last;

                // attempt to parse the alias
                webWalletAlias = uri.queryParameters['alias'];
              }

              // parse from a receive deep link
              final receiveParams = uri.queryParameters['receiveParams'];

              // uri
              final stringUri =
                  '${state.uri.scheme}://${state.uri.host}/#${state.uri.path}${state.uri.fragment}';

              return LandingScreen(
                uri: state.uri.hasScheme ? stringUri : state.uri.toString(),
                voucher: voucher,
                voucherParams: voucherParams,
                webWallet:
                    webWallet != null && webWallet.isEmpty ? null : webWallet,
                webWalletAlias: webWalletAlias,
                receiveParams: receiveParams,
                deepLink: deepLink,
                deepLinkParams: deepLinkParams,
              );
            }),
        GoRoute(
            path: '/recovery',
            builder: (context, state) {
              return const AccountRecoveryScreen();
            }),
        GoRoute(
            path: '/recovery/connected',
            builder: (context, state) {
              return const AccountConnectedScreen();
            }),
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
              pageBuilder: (context, state) {
                // parse from a deep link
                String? deepLinkParams;
                final deepLink = state.uri.queryParameters['dl'];
                if (deepLink != null) {
                  deepLinkParams = state.uri.queryParameters[deepLink];
                }

                return NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: WalletScreen(
                    state.pathParameters['address'],
                    state.uri.queryParameters['alias'],
                    wallet,
                    voucher: state.uri.queryParameters['voucher'],
                    voucherParams: state.uri.queryParameters['params'],
                    receiveParams: state.uri.queryParameters['receiveParams'],
                    deepLink: deepLink,
                    deepLinkParams: deepLinkParams,
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
                  alias: state.uri.queryParameters['alias'],
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
          builder: (context, state) => const SettingsScreen(),
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
          builder: (context, state) {
            String alias = Uri.base.host.endsWith(dotenv.get('APP_LINK_SUFFIX'))
                ? Uri.base.host.replaceFirst(dotenv.get('APP_LINK_SUFFIX'), '')
                : Uri.base.host;

            // parse from a deep link
            String? deepLinkParams;
            final deepLink = state.uri.queryParameters['dl'];
            if (deepLink != null) {
              deepLinkParams = state.uri.queryParameters[deepLink];
              if (deepLinkParams != null) {
                deepLinkParams = encodeParams(deepLinkParams);
              }
            }

            return WebLandingScreen(
              voucher: state.uri.queryParameters['voucher'],
              voucherParams: state.uri.queryParameters['params'],
              alias: alias,
              receiveParams: state.uri.queryParameters['receiveParams'],
              deepLink: deepLink,
              deepLinkParams: deepLinkParams,
            );
          },
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
                String alias =
                    Uri.base.host.endsWith(dotenv.get('APP_LINK_SUFFIX'))
                        ? Uri.base.host
                            .replaceFirst(dotenv.get('APP_LINK_SUFFIX'), '')
                        : Uri.base.host;

                // parse from a deep link
                String? deepLinkParams;
                final deepLink = state.uri.queryParameters['dl'];
                if (deepLink != null) {
                  deepLinkParams = state.uri.queryParameters[deepLink];
                  if (deepLinkParams != null) {
                    deepLinkParams = encodeParams(deepLinkParams);
                  }
                }

                return NoTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: PopScope(
                    canPop: false,
                    child: BurnerWalletScreen(
                      state.pathParameters['qr'] ?? '',
                      wallet,
                      alias: alias,
                      voucher: state.uri.queryParameters['voucher'],
                      voucherParams: state.uri.queryParameters['params'],
                      receiveParams: state.uri.queryParameters['receiveParams'],
                      deepLink: deepLink,
                      deepLinkParams: deepLinkParams,
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

                    return PopScope(
                      canPop: false,
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
