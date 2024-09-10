import 'package:citizenwallet/state/theme/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpAppWithRouter(Widget widget,
      {List<RouteBase> routes = const []}) async {
    await pumpWidget(
      provideAppState(
        null,
        builder: (context, child) => Theme(colors: context.select((ThemeState state) => state.colors), child: CupertinoApp.router(
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
      )
        
      ),
    );
  }
}
