import 'package:citizenwallet/router/router.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await PreferencesService().init();

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
    router = createRouter(_rootNavigatorKey, _shellNavigatorKey, []);
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
    final darkMode = context.select((AppState state) => state.darkMode);

    return CupertinoApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: CupertinoThemeData(
        brightness: darkMode ? Brightness.dark : Brightness.light,
      ),
    );
  }
}
