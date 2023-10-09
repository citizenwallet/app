import 'package:citizenwallet/services/nfc/nfc.dart';
import 'package:citizenwallet/state/cards/state.dart';
import 'package:flutter/cupertino.dart';

class CardsLogic {
  final NFCService _nfc = NFCService();
  final CardsState _state;

  CardsLogic(BuildContext context) : _state = CardsState();

  Future<void> init() async {
    _state.setAvailable(await _nfc.isAvailable);
  }

  Future<void> read() async {
    try {
      _nfc.read();
    } catch (e) {
      //
      print(e);
    }
  }
}
