import 'dart:convert';

import 'package:citizenwallet/models/transaction.dart' as transaction_model;
import 'package:citizenwallet/services/db/account/db.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:web3dart/web3dart.dart';

class TransactionState with ChangeNotifier {
  final String _transactionHash;
  transaction_model.CWTransaction? transaction;
  final AccountDBService _accountDBService = AccountDBService();
  final WalletService _wallet = WalletService();

  TransactionState({required String transactionHash})
      : _transactionHash = transactionHash;

  bool loading = false;

  bool _mounted = true;
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> fetchTransaction() async {
    try {
      loading = true;
      safeNotifyListeners();

      final dbTransaction = await _accountDBService.transactions
          .getTransactionByHash(_transactionHash);

      if (dbTransaction == null) {
        loading = false;
        transaction = null;
        safeNotifyListeners();
        return;
      }

      transaction = transaction_model.CWTransaction(
        fromDoubleUnit(
          dbTransaction.value.toString(),
          decimals: _wallet.currency.decimals,
        ),
        id: dbTransaction.hash,
        hash: dbTransaction.txHash,
        chainId: _wallet.chainId,
        from: EthereumAddress.fromHex(dbTransaction.from).hexEip55,
        to: EthereumAddress.fromHex(dbTransaction.to).hexEip55,
        description: dbTransaction.data != ''
            ? TransferData.fromJson(jsonDecode(dbTransaction.data)).description
            : '',
        date: dbTransaction.createdAt,
        state: transaction_model.TransactionState.values.firstWhereOrNull(
              (v) => v.name == dbTransaction.status,
            ) ??
            transaction_model.TransactionState.success,
      );

    } catch (_) {
    } finally {
      loading = false;
      safeNotifyListeners();
    }
  }
}
