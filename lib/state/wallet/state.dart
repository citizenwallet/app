import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:flutter/cupertino.dart';

class WalletState with ChangeNotifier {
  bool loading = false;
  bool error = false;

  Exception? errorException;

  int chainId = PreferencesService().chainId;
  CWWallet? wallet;

  bool transactionsLoading = false;
  bool transactionsError = false;

  int transactionsOffset = 0;
  int transactionsTotal = 0;
  DateTime transactionsMaxDate = DateTime.now();
  List<CWTransaction> transactions = [];

  bool transactionSendLoading = false;
  bool transactionSendError = false;

  bool parsingQRAddress = false;
  bool parsingQRAddressError = false;

  bool invalidAddress = false;
  bool invalidAmount = false;

  bool hasAddress = false;
  bool hasAmount = false;

  String receiveQR = '';

  String walletQR = '';

  bool isInvalidPassword = false;

  List<DBWallet> dbWallets = [];

  bool dbWalletsLoading = false;
  bool dbWalletsError = false;

  void setChainId(int chainId) {
    this.chainId = chainId;
    notifyListeners();
  }

  void switchChainRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void switchChainSuccess(CWWallet wallet) {
    transactions = [];
    this.wallet = wallet;

    loading = false;
    error = false;
    notifyListeners();
  }

  void switchChainError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void instantiateWallet() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void instantiateWalletSuccess() {
    loading = false;
    error = false;
    notifyListeners();
  }

  void instantiateWalletError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void loadWallet() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void loadWalletSuccess(
    CWWallet wallet,
  ) {
    this.wallet = wallet;
    transactions = [];

    loading = false;
    error = false;
    errorException = null;
    notifyListeners();
  }

  void loadWalletError({Exception? exception}) {
    loading = false;
    error = true;
    errorException = exception;
    notifyListeners();
  }

  void updateWallet() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void updateWalletSuccess() {
    loading = false;
    error = false;
    notifyListeners();
  }

  void updateWalletError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void updateWalletBalance() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void updateWalletBalanceSuccess(String balance) {
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
    transactionsLoading = true;
    transactionsError = false;
    notifyListeners();
  }

  void loadTransactionsSuccess(
    List<CWTransaction> transactions, {
    int offset = 0,
    int total = 0,
    DateTime? maxDate,
  }) {
    transactionsOffset = offset;
    transactionsTotal = total;
    transactionsMaxDate = maxDate ?? DateTime.now();
    this.transactions = transactions;

    transactionsLoading = false;
    transactionsError = false;
    notifyListeners();
  }

  void loadTransactionsError() {
    transactionsLoading = false;
    transactionsError = true;
    notifyListeners();
  }

  void loadAdditionalTransactions() {
    transactionsLoading = true;
    transactionsError = false;
    notifyListeners();
  }

  void loadAdditionalTransactionsSuccess(List<CWTransaction> transactions,
      {int offset = 0, int total = 0}) {
    transactionsOffset = offset;
    transactionsTotal = total;
    for (final transaction in transactions) {
      final index = this.transactions.indexWhere((t) => t.id == transaction.id);
      if (index == -1) {
        this.transactions.add(transaction);
      } else {
        this.transactions[index] = transaction;
      }
    }

    transactionsLoading = false;
    transactionsError = false;
    notifyListeners();
  }

  void loadAdditionalTransactionsError() {
    transactionsLoading = false;
    transactionsError = true;
    notifyListeners();
  }

  void sendTransaction() {
    setInvalidAmount(false);
    setInvalidAddress(false);
    transactionSendLoading = true;
    transactionSendError = false;
    notifyListeners();
  }

  void sendingTransaction(CWTransaction? transaction) {
    if (transaction != null) {
      transactions = transactions
          .where((element) => element.id != pendingTransactionId)
          .toList();

      transactions.insert(0, transaction);
    }
    notifyListeners();
  }

  void sendTransactionSuccess(CWTransaction? transaction) {
    if (transaction != null) {
      transactions = transactions
          .where((element) => element.id != pendingTransactionId)
          .toList();

      transactions.insert(0, transaction);
    }
    transactionSendLoading = false;
    transactionSendError = false;
    notifyListeners();
  }

  void sendTransactionError() {
    transactionSendLoading = false;
    transactionSendError = true;
    notifyListeners();
  }

  void incomingTransactionsRequest() {
    transactionsLoading = true;
    transactionsError = false;
    notifyListeners();
  }

  void incomingTransactionsRequestSuccess(List<CWTransaction> transactions) {
    if (transactions.isNotEmpty) {
      for (final transaction in transactions) {
        final index =
            this.transactions.indexWhere((t) => t.id == transaction.id);
        if (index == -1) {
          this.transactions.insert(0, transaction);
        } else {
          this.transactions[index] = transaction;
        }
      }

      this.transactions = this
          .transactions
          .where((element) => element.id != pendingTransactionId)
          .toList();
    }

    transactionsLoading = false;
    transactionsError = false;
    notifyListeners();
  }

  void incomingTransactionsRequestError() {
    transactionsLoading = false;
    transactionsError = true;
    notifyListeners();
  }

  void resetInvalidInputs() {
    invalidAmount = false;
    invalidAddress = false;
    hasAddress = false;
    hasAmount = false;
  }

  void setInvalidAmount(bool invalid) {
    invalidAmount = invalid;
    notifyListeners();
  }

  void setInvalidAddress(bool invalid) {
    invalidAddress = invalid;
    notifyListeners();
  }

  void parseQRAddress() {
    parsingQRAddress = true;
    parsingQRAddressError = false;
    notifyListeners();
  }

  void parseQRAddressSuccess() {
    parsingQRAddress = false;
    parsingQRAddressError = false;

    invalidAddress = false;
    transactionSendError = false;

    notifyListeners();
  }

  void parseQRAddressError() {
    parsingQRAddress = false;
    parsingQRAddressError = true;
    notifyListeners();
  }

  void clearReceiveQR() {
    receiveQR = '';
    notifyListeners();
  }

  void updateReceiveQR(String qr) {
    receiveQR = qr;
    notifyListeners();
  }

  void setHasAddress(bool hasAddress) {
    this.hasAddress = hasAddress;
    if (hasAddress) {
      parsingQRAddress = false;
      parsingQRAddressError = false;
      invalidAddress = false;
    }
    notifyListeners();
  }

  void setHasAmount(bool hasAmount) {
    this.hasAmount = hasAmount;
    if (hasAmount) {
      invalidAmount = false;
    }
    notifyListeners();
  }

  void clearWalletQR() {
    walletQR = '';
    notifyListeners();
  }

  void updateWalletQR(String qr) {
    walletQR = qr;
    notifyListeners();
  }

  void setInvalidPassword(bool invalid) {
    isInvalidPassword = invalid;
    notifyListeners();
  }

  void loadDBWallets() {
    dbWalletsLoading = true;
    dbWalletsError = false;
    notifyListeners();
  }

  void loadDBWalletsSuccess(List<DBWallet> wallets) {
    dbWallets = wallets;

    dbWalletsLoading = false;
    dbWalletsError = false;
    notifyListeners();
  }

  void loadDBWalletsError() {
    dbWalletsLoading = false;
    dbWalletsError = true;
    notifyListeners();
  }

  void createDBWallet() {
    dbWalletsLoading = true;
    dbWalletsError = false;
    notifyListeners();
  }

  void createDBWalletSuccess(DBWallet wallet) {
    dbWallets.insert(0, wallet);

    dbWalletsLoading = false;
    dbWalletsError = false;
    notifyListeners();
  }

  void createDBWalletError() {
    dbWalletsLoading = false;
    dbWalletsError = true;
    notifyListeners();
  }
}
