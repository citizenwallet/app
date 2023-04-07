import 'package:citizenwallet/state/app/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

provideAppState(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
      ],
      child: child,
    );
