import 'package:citizenwallet/router/shell.dart';
import 'package:citizenwallet/screens/about/screen.dart';
import 'package:citizenwallet/screens/accounts/screen.android.dart';
import 'package:citizenwallet/screens/accounts/screen.apple.dart';
import 'package:citizenwallet/screens/accounts/screen.dart';
import 'package:citizenwallet/screens/deeplink/deep_link.dart';
import 'package:citizenwallet/screens/landing/account_connected.dart';
import 'package:citizenwallet/screens/landing/account_recovery.dart';
import 'package:citizenwallet/screens/landing/screen.dart';
import 'package:citizenwallet/screens/landing/screen.web.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/screens/transaction/screen.dart';
import 'package:citizenwallet/screens/vouchers/screen.dart';
import 'package:citizenwallet/screens/vouchers/voucher_read.dart';
import 'package:citizenwallet/screens/wallet/receive.dart';
import 'package:citizenwallet/screens/wallet/screen.dart';
import 'package:citizenwallet/screens/wallet/screen.web.dart';
import 'package:citizenwallet/screens/wallet/send.dart';
import 'package:citizenwallet/screens/webview/screen.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

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
        GoRoute(
          name: 'Wallet',
          path: '/wallet/:address',
          parentNavigatorKey: rootNavigatorKey,
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
            GoRoute(
              name: 'Send',
              path: 'send',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return SendScreen(
                  walletLogic: extra['walletLogic'],
                  profilesLogic: extra['profilesLogic'],
                  receiveParams: extra['receiveParams'],
                  id: extra['id'],
                );
              },
            ),
            GoRoute(
              name: 'Receive',
              path: 'receive',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return ReceiveScreen(
                  logic: extra['logic'],
                );
              },
            ),
            GoRoute(
              name: 'Mint',
              path: 'mint',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return SendScreen(
                  walletLogic: extra['walletLogic'],
                  profilesLogic: extra['profilesLogic'],
                  receiveParams: extra['receiveParams'],
                  isMinting: true,
                );
              },
            ),
            GoRoute(
              name: 'Vouchers',
              path: 'vouchers',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => const VouchersScreen(),
            ),
            GoRoute(
              name: 'Account',
              path: 'accounts',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) => CupertinoScaffold(
                key: const Key('accounts-screen'),
                topRadius: const Radius.circular(40),
                transitionBackgroundColor: ThemeColors.transparent,
                body: AccountsScreen(
                  logic: wallet,
                  currentAddress: state.pathParameters['address'],
                ),
              ),
            ),
            GoRoute(
              name: 'Webview',
              path: 'webview',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return WebViewScreen(
                  url: extra['url'],
                  redirectUrl: extra['redirectUrl'],
                  customScheme: extra['customScheme'],
                );
              },
            ),
            GoRoute(
              name: 'Voucher',
              path: 'voucher',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return VoucherReadScreen(
                  address: extra['address'],
                  logic: extra['logic'],
                );
              },
            ),
            GoRoute(
              name: 'DeepLink',
              path: 'deeplink',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) {
                if (state.extra == null) {
                  return const SizedBox();
                }

                final extra = state.extra as Map<String, dynamic>;

                return ChangeNotifierProvider(
                  create: (_) => DeepLinkState(extra['deepLink']),
                  child: DeepLinkScreen(
                    wallet: extra['wallet'],
                    deepLink: extra['deepLink'],
                    deepLinkParams: extra['deepLinkParams'],
                  ),
                );
              },
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
