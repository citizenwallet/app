import 'package:citizenwallet/services/connect/connect.dart';
import 'package:citizenwallet/state/connect/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class ConnectLogic extends WidgetsBindingObserver {
  final ConnectState _state;
  final ConnectService _connect;

  ConnectLogic(
    BuildContext context,
    String account,
    String address,
  )   : _state = context.read<ConnectState>(),
        _connect = ConnectService(
          dotenv.get('WC_PROJECT_ID'),
          '1',
          account,
          address,
        );

  Future<void> init() async {
    print('init');
    try {
      await _connect.init();

      _state.setReady(true);
      return;
    } catch (e) {
      //
      print(e);
    }
    _state.setReady(false);
  }

  Future<void> connect(String uri) async {
    print('connect');
    try {
      _connect.connect(uri, onMetadata: (metadata) {
        _state.setMetadata(metadata);
      });
    } catch (e) {
      //
      print(e);
    }
  }

  Future<void> accept(AuthMetadata metadata, EthPrivateKey credentials) async {
    try {
      _connect.approveSession(metadata, credentials);
    } catch (e) {
      //
      print(e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // connect;
        break;
      default:
      // pause;
    }
  }
}
