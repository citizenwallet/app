import 'dart:async';

import 'package:citizenwallet/firebase_options.dart';
import 'package:citizenwallet/router/router.dart';
import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:citizenwallet/state/theme/logic.dart';
import 'package:citizenwallet/state/theme/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/notifications/notification_banner.dart';
import 'package:citizenwallet/widgets/notifications/toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: kIsWeb && !kDebugMode ? '.web.env' : '.env');

  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('fr', timeago.FrMessages());
  timeago.setLocaleMessages('nl', timeago.NlMessages());

  // await initSentry(
  //   kDebugMode,
  //   dotenv.get('SENTRY_URL'),
  //   appRunner,
  // );
  appRunner();
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
}

class MyAppState extends State<MyApp> {
  late GoRouter router;
  late WalletLogic _logic;
  late NotificationsLogic _notificationsLogic;
  final ThemeLogic _themeLogic = ThemeLogic();

  final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final _shellNavigatorKey = GlobalKey<NavigatorState>();
  @override
  void initState() {
    super.initState();

    _notificationsLogic = NotificationsLogic(context);
    _logic = WalletLogic(context, _notificationsLogic);

    _themeLogic.init(context);

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
    final cupertinoTheme =
        context.select((ThemeState state) => state.cupertinoTheme);
    final colors = context.select((ThemeState state) => state.colors);

    final config = context.select((WalletState s) => s.config);

    final title = context.select((NotificationsState s) => s.title);
    final display = context.select((NotificationsState s) => s.display);

    final toastTitle = context.select((NotificationsState s) => s.toastTitle);
    final toastDisplay =
        context.select((NotificationsState s) => s.toastDisplay);

    final titlePrefix = config?.token.symbol ?? 'Citizen';

    final language = context.select((AppState state) => state.language);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        colors: colors,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            CupertinoApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: router,
              theme: cupertinoTheme,
              title: '$titlePrefix Wallet',
              locale: Locale(language.code),
              localizationsDelegates: const [
                AppLocalizations.delegate, // Add this line
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'), // English
                Locale('fr'), // fench
                Locale('nl'), // ductch
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: CupertinoScaffold(
                  key: const Key('main'),
                  topRadius: const Radius.circular(40),
                  transitionBackgroundColor: colors.transparent,
                  body: CupertinoPageScaffold(
                    key: const Key('main'),
                    backgroundColor: colors.transparent.resolveFrom(context),
                    child: Column(
                      children: [
                        Expanded(
                          child: child != null
                              ? CupertinoTheme(
                                  data: cupertinoTheme,
                                  child: child,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
    );
  }
}
