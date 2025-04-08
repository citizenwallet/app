import 'package:citizenwallet/services/nfc/nfc.dart';
import 'package:citizenwallet/state/cards/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:web3dart/web3dart.dart';

class CardsLogic {
  final NFCService _nfc = NFCService();
  final CardsState _state;

  CardsLogic(BuildContext context) : _state = CardsState();

  Future<void> init() async {
    _state.setAvailable(await _nfc.isAvailable);
  }

  Future<void> fetchCards() async {
    //
  }

  Future<void> read() async {
    try {
      final card = await _nfc.readCard();
      // if (card == null) {
      //   throw Exception('Invalid card.');
      // }

      // print('Card read successfully ${card.uid} ${card.account} ${card.alias}');
      // print('signature ${card.signature}');
    } catch (e) {
      //
      print(e);
    }
  }

  Future<void> configure(
      EthPrivateKey credentials, String account, String alias) async {
    try {
      await _nfc.configureCard(credentials, account, alias);
    } catch (e) {
      //
      print(e);
    }
  }
}
