import 'package:citizenwallet/state/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpAppWithRouter(Widget widget,
      {List<RouteBase> routes = const []}) async {
    await pumpWidget(
      provideAppState(
        CupertinoApp.router(
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
