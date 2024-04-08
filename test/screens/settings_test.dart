// widget test for header widget

import 'dart:io';

import 'package:citizenwallet/screens/about/screen.dart';
import 'package:citizenwallet/screens/settings/screen.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nock/nock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock_http.dart';
import '../router_extension.dart';

void main() async {
  setUpAll(() async {
    nock.init();

    TestWidgetsFlutterBinding.ensureInitialized();

    dotenv.load();

    SharedPreferences.setMockInitialValues({});

    return PreferencesService().init(await SharedPreferences.getInstance());
  });

  setUp(() async {
    nock.cleanAll();

    registerFallbackValue(Uri());

    // Load an image from assets and transform it from bytes to List<int>
    final imageByteData = await rootBundle.load('assets/logo_small.png');
    final imageIntList = imageByteData.buffer.asInt8List();

    final requestsMap = {
      Uri.parse(
              'https://github.com/citizenwallet/app/blob/main/assets/logo_small.png?raw=true'):
          imageIntList,
    };

    HttpOverrides.global = MockHttpOverrides(requestsMap);
  });

  group('Settings', () {
    testWidgets('Settings screen with about page', (widgetTester) async {
      widgetTester.view.physicalSize = const Size(800, 1200);
      await widgetTester.pumpAppWithRouter(
        const SettingsScreen(),
        routes: [
          GoRoute(
            name: 'About',
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          )
        ],
      );

      await widgetTester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);

      expect(find.text('About'), findsOneWidget);

      await widgetTester.tap(find.text('About'));

      await widgetTester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);

      expect(find.byKey(const Key('about-markdown')), findsOneWidget);

      expect(reason: 'Markdown should have some specific content',
          find.byWidgetPredicate((widget) {
        if (widget is Markdown) {
          return widget.data.contains('ERC4337');
        }
        return false;
      }), findsOneWidget);
    });
  });
}
