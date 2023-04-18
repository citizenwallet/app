import 'dart:async';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class WalletLogic {
  late WalletState _state;
  late WalletService _wallet;

  late StreamSubscription<String> _blockSubscription;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TextEditingController get addressController => _addressController;
  TextEditingController get amountController => _amountController;
  TextEditingController get messageController => _messageController;

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

      _blockSubscription = _wallet.blockStream.listen(onBlockHash);

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

  void onBlockHash(String hash) async {
    try {
      _state.incomingTransactionsRequest();

      final transactions = await _wallet.transactionsForBlockHash(hash);

      _state.incomingTransactionsRequestSuccess(
        transactions
            .map((e) => CWTransaction(
                  e.value.getInEther.toDouble(),
                  id: e.hash,
                  chainId: _wallet.chainId,
                  from: e.from.hex,
                  to: e.to.hex,
                  title: e.input?.message ?? '',
                  date: e.timestamp,
                ))
            .toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.incomingTransactionsRequestError();
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      final transactions = await _wallet.transactions();

      _state.loadTransactionsSuccess(
        transactions
            .map((e) => CWTransaction(
                  e.value.getInEther.toDouble(),
                  id: e.hash,
                  chainId: _wallet.chainId,
                  from: e.from.hex,
                  to: e.to.hex,
                  title: e.input?.message ?? '',
                  date: e.timestamp,
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

  Future<bool> sendTransaction(String amount, String to,
      {String message = ''}) async {
    try {
      _state.sendTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      var doubleAmount = double.tryParse(amount.replaceAll(',', '.'));
      if (doubleAmount == null) {
        _state.setInvalidAmount(true);
        throw Exception('invalid amount');
      }

      doubleAmount = doubleAmount * 100;

      final hash = await _wallet.sendTransaction(
        to: to,
        amount: doubleAmount.toInt(),
        message: message,
      );

      _state.sendTransactionSuccess(CWTransaction.pending(
        doubleAmount,
        id: hash,
        title: message,
        date: DateTime.now(),
      ));

      _addressController.clear();
      _amountController.clear();
      _messageController.clear();

      await updateBalance();

      return true;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.sendTransactionError();

    return false;
  }

  void updateAddress(String address) {
    _addressController.text = address;
  }

  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    _wallet.dispose();
    _blockSubscription.cancel();
  }
}
