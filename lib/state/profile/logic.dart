import 'package:citizenwallet/services/wallet/wallet2.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:flutter/cupertino.dart';

class ProfileLogic {
  late ProfileState _state;

  final WalletService2 _wallet = WalletService2();

  ProfileLogic(BuildContext context) {
    _state = ProfileState();
  }
}
