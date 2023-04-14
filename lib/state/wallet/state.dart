import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:flutter/cupertino.dart';

class WalletState extends ChangeNotifier {
  bool loading = false;
  bool error = false;

  CWWallet? wallet;

  bool transactionsLoading = false;
  bool transactionsError = false;

  List<CWTransaction> transactions = [];

  void loadWallet() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void loadWalletSuccess(CWWallet wallet) {
    this.wallet = wallet;

    loading = false;
    error = false;
    notifyListeners();
  }

  void loadWalletError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void updateWalletBalance() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void updateWalletBalanceSuccess(double balance) {
    wallet!.setBalance(balance);

    loading = false;
    error = false;
    notifyListeners();
  }

  void updateWalletBalanceError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void loadTransactions() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void loadTransactionsSuccess(List<CWTransaction> transactions) {
    this.transactions = transactions;

    loading = false;
    error = false;
    notifyListeners();
  }

  void loadTransactionsError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void loadAdditionalTransactions() {
    transactionsLoading = true;
    transactionsError = false;
    notifyListeners();
  }

  void loadAdditionalTransactionsSuccess(List<CWTransaction> transactions) {
    this.transactions.insertAll(0, transactions);

    transactionsLoading = false;
    transactionsError = false;
    notifyListeners();
  }

  void loadAdditionalTransactionsError() {
    transactionsLoading = false;
    transactionsError = true;
    notifyListeners();
  }
}
