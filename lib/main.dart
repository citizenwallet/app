import 'dart:async';

import 'package:citizenwallet/firebase_options.dart';
import 'package:citizenwallet/router/router.dart';
import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/sentry/sentry.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/widgets/notifications/notification_banner.dart';
import 'package:citizenwallet/widgets/notifications/toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: kIsWeb && !kDebugMode ? '.web.env' : '.env');

  await initSentry(
    kDebugMode,
    dotenv.get('SENTRY_URL'),
    appRunner,
  );
}

FutureOr<void> appRunner() async {
  await PreferencesService().init(await SharedPreferences.getInstance());

  DBService();

  WalletService();

  final config = ConfigService();

  if (kIsWeb) {
    config.initWeb();
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    config.init(
      dotenv.get('WALLET_CONFIG_URL'),
    );
  }

  await AudioService().init(muted: PreferencesService().muted);

  runApp(provideAppState(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  MyAppState createState() => MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) async {
    MyAppState? state = context.findAncestorStateOfType<MyAppState>();
    var prefs = await SharedPreferences.getInstance();
    prefs.setString('languageCode', newLocale.languageCode);
    state?.setState(() {
      state._locale = newLocale;
    });
  }
}

/*
  To get local from SharedPreferences if exists
   */
Future<Locale> _fetchLocale() async {
  var prefs = await SharedPreferences.getInstance();

  String languageCode = prefs.getString('languageCode') ?? 'en';

  return Locale(languageCode);
}

class MyAppState extends State<MyApp> {
  late GoRouter router;
  late WalletLogic _logic;
  late NotificationsLogic _notificationsLogic;

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();

  var prefs = SharedPreferences.getInstance();

  Locale? _locale;

  @override
  void initState() {
    super.initState();

    _notificationsLogic = NotificationsLogic(context);
    _logic = WalletLogic(context, _notificationsLogic);

    router = kIsWeb
        ? createWebRouter(_rootNavigatorKey, _shellNavigatorKey, [], _logic)
        : createRouter(_rootNavigatorKey, _shellNavigatorKey, [], _logic);

    WidgetsBinding.instance.addObserver(_logic);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      onLoad();
    });

    _fetchLocale().then((locale) {
      setState(() {
        _locale = locale;
      });
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
    _notificationsLogic.checkPushPermissions();

    await _logic.fetchWalletConfig();
  }

  void handleDismissNotification() {
    _notificationsLogic.hide();
  }

  void handleDismissToast() {
    _notificationsLogic.toastHide();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final theme = context.select((AppState state) => state.theme);

    final config = context.select((WalletState s) => s.config);

    final title = context.select((NotificationsState s) => s.title);
    final display = context.select((NotificationsState s) => s.display);

    final toastTitle = context.select((NotificationsState s) => s.toastTitle);
    final toastDisplay =
        context.select((NotificationsState s) => s.toastDisplay);

    final titlePrefix = config?.token.symbol ?? 'Citizen';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          CupertinoApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: theme,
            title: '$titlePrefix Wallet',
            locale: _locale,
            localizationsDelegates: [
              AppLocalizations.delegate, // Add this line
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              Locale('en'), // English
              Locale('fr'), // fench
              Locale('nl'), // ductch
            ],
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child ?? const SizedBox(),
            ),
          ),
          Toast(
            title: toastTitle,
            display: toastDisplay,
            onDismiss: handleDismissToast,
          ),
          NotificationBanner(
            title: title,
            display: display,
            onDismiss: handleDismissNotification,
          ),
        ],
      ),
    );
  }
}
