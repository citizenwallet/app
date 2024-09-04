import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpAppWithRouter(Widget widget,
      {List<RouteBase> routes = const []}) async {
    await pumpWidget(
      provideAppState(
        CupertinoApp.router(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate, // Add this line
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('fr'), // French
            Locale('nl'), // Dutch
          ],
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => widget,
              ),
              ...routes,
            ],
          ),
          theme: CupertinoThemeData(
            brightness:
                SchedulerBinding.instance.platformDispatcher.platformBrightness,
          ),
        ),
      ),
    );
  }
}
