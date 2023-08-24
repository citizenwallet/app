import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/share_modal/state.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

Widget provideAppState(Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfilesState(),
        ),
        ChangeNotifierProvider(
          create: (_) => VoucherState(),
        ),
        if (kIsWeb)
          ChangeNotifierProvider(
            create: (_) => ShareModalState(),
          ),
      ],
      child: child,
    );
