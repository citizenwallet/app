import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/wallet/utils.dart';
import 'package:collection/collection.dart';
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
  DateTime transactionsMaxDate = DateTime.now().toUtc();
  DateTime transactionsFromDate = DateTime.now().toUtc();
  List<CWTransaction> transactions = [];

  bool transactionSendLoading = false;
  bool transactionSendError = false;

  List<CWTransaction> transactionSendQueue = [];

  bool parsingQRAddress = false;
  bool parsingQRAddressError = false;

  bool invalidAddress = false;
  bool invalidAmount = false;

  bool hasAddress = false;
  bool hasAmount = false;

  String receiveQR = '';

  String walletQR = '';

  bool isInvalidPassword = false;

  List<CWWallet> wallets = [];

  bool cwWalletsLoading = false;
  bool cwWalletsError = false;

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
    if (this.wallet != null && this.wallet!.address != wallet.address) {
      transactions = [];
    }

    this.wallet = wallet;

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
    transactionsMaxDate = maxDate ?? DateTime.now().toUtc();
    transactionsFromDate = maxDate ?? DateTime.now().toUtc();
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

  void sendingTransaction(CWTransaction transaction) {
    sendQueueRemoveTransaction(transaction.id);

    transactions =
        transactions.where((element) => element.id != transaction.id).toList();

    transactions.insert(0, transaction);

    notifyListeners();
  }

  void sendTransactionSuccess(CWTransaction? transaction) {
    if (transaction != null) {
      transactions = transactions
          .where((element) => element.id != transaction.id)
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
          .where((element) => !isPendingTransactionId(element.id))
          .toList();
    }

    transactionsFromDate =
        DateTime.now().toUtc().subtract(const Duration(seconds: 1));

    transactionsLoading = false;
    transactionsError = false;
    notifyListeners();
  }

  void incomingTransactionsRequestError() {
    transactionsLoading = false;
    transactionsError = true;
    notifyListeners();
  }

  void resetTransactionSendProperties({bool notify = false}) {
    transactionSendError = false;
    transactionSendLoading = false;

    if (notify) {
      notifyListeners();
    }
  }

  void resetInvalidInputs({bool notify = false}) {
    invalidAmount = false;
    invalidAddress = false;
    hasAddress = false;
    hasAmount = false;

    if (notify) {
      notifyListeners();
    }
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

  void loadWallets() {
    cwWalletsLoading = true;
    cwWalletsError = false;
    notifyListeners();
  }

  void loadWalletsSuccess(List<CWWallet> wallets) {
    this.wallets = wallets;

    cwWalletsLoading = false;
    cwWalletsError = false;
    notifyListeners();
  }

  void loadWalletsError() {
    cwWalletsLoading = false;
    cwWalletsError = true;
    notifyListeners();
  }

  void createWallet() {
    cwWalletsLoading = true;
    cwWalletsError = false;
    notifyListeners();
  }

  void createWalletSuccess(CWWallet wallet) {
    wallets.insert(0, wallet);

    cwWalletsLoading = false;
    cwWalletsError = false;
    notifyListeners();
  }

  void createWalletError() {
    cwWalletsLoading = false;
    cwWalletsError = true;
    notifyListeners();
  }

  // get queued transaction by id
  CWTransaction? getQueuedTransaction(String id) {
    return transactionSendQueue.firstWhereOrNull((t) => t.id == id);
  }

  // get queued transaction by id and set it as pending
  CWTransaction? attemptRetryQueuedTransaction(String id) {
    final i = transactionSendQueue.indexWhere((t) => t.id == id);

    if (i < 0) {
      return null;
    }

    final tx = transactionSendQueue[i].copyWith(
      state: TransactionState.pending,
    );

    transactionSendQueue.removeAt(i);

    notifyListeners();

    return tx;
  }

  // clear transactions queue
  void sendQueueClearTransactions() {
    transactionSendQueue = [];
    notifyListeners();
  }

  // update queued transaction
  void sendQueueUpdateTransaction(CWTransaction transaction) {
    final index =
        transactionSendQueue.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactionSendQueue[index] = transaction;
      notifyListeners();
    }
  }

  // add transaction to queue
  void sendQueueAddTransaction(CWTransaction transaction) {
    transactionSendQueue.insert(0, transaction);

    transactions =
        transactions.where((element) => element.id != transaction.id).toList();

    notifyListeners();
  }

  // remove transaction from queue
  void sendQueueRemoveTransaction(String id) {
    transactionSendQueue =
        transactionSendQueue.where((t) => t.id != id).toList();
    notifyListeners();
  }
}
