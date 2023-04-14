import 'dart:async';
import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/models/message.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class WalletLogic {
  late WalletState _state;
  late WalletService _wallet;

  WalletLogic(BuildContext context) {
    _state = context.read<WalletState>();
  }

  Future<void> openWallet() async {
    // final random = Random.secure();

    // final wallet = Wallet.createNew(
    //   EthPrivateKey.fromHex(dotenv.get('TEST_PRIVATE_KEY')),
    //   dotenv.get('TEST_WALLET_PASSWORD'),
    //   random,
    // );

    // _wallet = WalletService.fromWalletFile(
    //   dotenv.get('DEFAULT_RPC_URL'),
    //   wallet.toJson(),
    //   dotenv.get('TEST_WALLET_PASSWORD'),
    // );

    try {
      _state.loadWallet();

      final wallet = await walletServiceFromChain(
        BigInt.from(1337),
        dotenv.get('TEST_WALLET'),
        dotenv.get('TEST_WALLET_PASSWORD'),
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      // _wallet = WalletService.fromWalletFile(
      //   dotenv.get('DEFAULT_RPC_URL'),
      //   dotenv.get('TEST_WALLET'),
      //   dotenv.get('TEST_WALLET_PASSWORD'),
      // );

      await _wallet.init();

      final balance = await _wallet.balance;
      final currency = _wallet.nativeCurrency;

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: currency.name,
          address: _wallet.address.hex,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
        ),
      );

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      final transactions = await _wallet.transactions(limit: 100000000);

      _state.loadTransactionsSuccess(
        transactions
            .map((e) => CWTransaction(
                  e.value.getInEther.toDouble(),
                  id: e.hash,
                  chainId: _wallet.chainId,
                  from: e.from.hex,
                  to: e.to.hex,
                  title: e.input?.message ?? '',
                  date: e.input?.date ?? DateTime.now(),
                ))
            .toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadTransactionsError();
  }

  Future<void> updateBalance() async {
    try {
      _state.updateWalletBalance();

      final balance = await _wallet.balance;

      _state.updateWalletBalanceSuccess(balance);
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.updateWalletBalanceError();
  }

  Future<void> sendTransaction(double amount) async {
    try {
      await _wallet.sendTransaction(
        to: dotenv.get('TEST_DESTINATION_ADDRESS'),
        amount: amount.toInt(),
      );

      await updateBalance();
    } catch (e) {
      print('error');
      print(e);
    }
  }

  void dispose() {
    _wallet.dispose();
  }
}
