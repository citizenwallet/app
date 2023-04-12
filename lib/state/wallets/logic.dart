import 'package:citizenwallet/state/wallets/mock_data.dart';
import 'package:citizenwallet/state/wallets/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletsLogic {
  late WalletsState _state;

  WalletsLogic(BuildContext context) {
    _state = context.read<WalletsState>();
  }

  Future<void> getWallet(int id) async {
    _state.walletRequest();

    try {
      // final wallet = await _api.getWallet(id);
      final wallet = mockWallets.firstWhere((w) => w.id == id);

      _state.walletSuccess(wallet);
    } catch (e) {
      _state.walletError();
    }
  }

  Future<void> getWallets() async {
    _state.walletListRequest();

    try {
      // final wallets = await _api.getWallets();

      _state.walletListSuccess(mockWallets);
    } catch (e) {
      _state.walletListError();
    }
  }

  Future<void> getTransactions(int id) async {
    _state.transactionListRequest();

    try {
      // final transactions = await _api.getTransactions(id);

      _state.transactionListSuccess(mockTransactions);
    } catch (e) {
      _state.transactionListError();
    }
  }
}
