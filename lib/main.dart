import 'dart:async';

import 'package:citizenwallet/router/router.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/sentry/sentry.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  await PreferencesService().init();
  await EncryptedPreferencesService().init(dotenv.get(
    'ENCRYPTED_STORAGE_GROUP_ID',
  ));

  await DBService().init('citizenwallet');

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

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  MyAppState() {
    router = kIsWeb
        ? createWebRouter(_rootNavigatorKey, _shellNavigatorKey, [])
        : createRouter(_rootNavigatorKey, _shellNavigatorKey, []);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
    });
  }

  @override
  void dispose() {
    router.dispose();

    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final theme = context.select((AppState state) => state.theme);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
    );
  }
}
