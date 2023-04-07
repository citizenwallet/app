import 'package:citizenwallet/state/wallet/mock_data.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class WalletLogic {
  late WalletState _state;

  WalletLogic(BuildContext context) {
    _state = context.read<WalletState>();
  }

  Future<void> getWallet(int id) async {
    _state.walletRequest();

    try {
      // final wallet = await _api.getWallet(id);
      final wallet = mockWallets.firstWhere((w) => w.id == id);
      await delay(const Duration(seconds: 1));

      _state.walletSuccess(wallet);
    } catch (e) {
      _state.walletError();
    }
  }

  Future<void> getWallets() async {
    _state.walletListRequest();

    try {
      // final wallets = await _api.getWallets();
      await delay(const Duration(seconds: 1));

      _state.walletListSuccess(mockWallets);
    } catch (e) {
      _state.walletListError();
    }
  }

  Future<void> getTransactions(int id) async {
    _state.transactionListRequest();

    try {
      // final transactions = await _api.getTransactions(id);
      await delay(const Duration(seconds: 1));

      _state.transactionListSuccess(mockTransactions);
    } catch (e) {
      _state.transactionListError();
    }
  }
}
