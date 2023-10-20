import 'dart:async';

import 'package:citizenwallet/router/router.dart';
import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/sentry/sentry.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await dotenv.load(fileName: '.env');

  await initSentry(
    kDebugMode,
    dotenv.get('SENTRY_URL'),
    appRunner,
  );
}

FutureOr<void> appRunner() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesService().init(await SharedPreferences.getInstance());

  DBService();

  WalletService();

  ConfigService();

  await AudioService().init(muted: PreferencesService().muted);

  runApp(provideAppState(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late GoRouter router;
  late WalletLogic _logic;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    _logic = WalletLogic(context);

    router = kIsWeb
        ? createWebRouter(_rootNavigatorKey, _shellNavigatorKey, [], _logic)
        : createRouter(_rootNavigatorKey, _shellNavigatorKey, [], _logic);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      onLoad();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_logic);

    _logic.dispose();

    router.dispose();

    super.dispose();
  }

  void onLoad() async {
    await _logic.fetchWalletConfig();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final theme = context.select((AppState state) => state.theme);

    final config = context.select((WalletState s) => s.config);

    final titlePrefix = config?.token.symbol ?? 'Citizen';

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      title: '$titlePrefix Wallet',
    );
  }
}
