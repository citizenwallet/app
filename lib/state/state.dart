import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/state/backup/state.dart';
import 'package:citizenwallet/state/cards/state.dart';
import 'package:citizenwallet/state/communities/state.dart';
import 'package:citizenwallet/state/notifications/state.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/backup_web/state.dart';
import 'package:citizenwallet/state/theme/state.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/state/scan/state.dart';
import 'package:citizenwallet/state/wallet_connect/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

Widget provideAppState(Widget? child,
        {Widget Function(BuildContext, Widget?)? builder}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeState(),
        ),
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
        ChangeNotifierProvider(
          create: (_) => CommunitiesState(),
        ),
        ChangeNotifierProvider(
          create: (_) => ScanState(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationsState(),
        ),
        ChangeNotifierProvider(
          create: (_) => BackupState(),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletConnectState(),
        ),
        if (!kIsWeb)
          ChangeNotifierProvider(
            create: (_) => CardsState(),
          ),
        if (kIsWeb)
          ChangeNotifierProvider(
            create: (_) => BackupWebState(),
          ),
      ],
      builder: builder,
      child: child,
    );
