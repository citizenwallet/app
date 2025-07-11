import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/engine/events.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/state/wallet/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

enum ActionButtonType {
  vouchers,
  plugins,
  minter,
  more,
}

class ActionButton {
  final String label;
  final ActionButtonType buttonType;

  ActionButton({
    required this.label,
    required this.buttonType,
  });
}

class WalletState with ChangeNotifier {
  bool cleaningUp = false;
  bool firstLoad = true;
  bool loading = true;
  bool error = false;

  EventServiceState eventServiceState = EventServiceState.disconnected;
  bool eventServiceIntentionalDisconnect = true;

  Exception? errorException;

  int chainId = PreferencesService().chainId;
  CWWallet? wallet;
  bool isBalanceReady = false;

  bool transactionsLoading = false;
  bool transactionsError = false;

  int transactionsOffset = 0;
  bool transactionsHasMore = false;
  DateTime transactionsMaxDate = DateTime.now().toUtc();
  DateTime transactionsFromDate = DateTime.now().toUtc();
  List<CWTransaction> transactions = [];

  bool walletActionsLoading = false;
  List<ActionButton> walletActions = [];

  bool transactionSendLoading = false;
  bool transactionSendError = false;

  List<CWTransaction> transactionSendQueue = [];

  bool parsingQRAddress = false;
  bool parsingQRAddressError = false;

  String? invalidScanMessage;
  bool invalidAddress = false;
  bool invalidAmount = false;

  bool hasAddress = false;
  bool hasAmount = false;

  String amount = '';
  String message = '';

  String receiveQR = '';

  String walletQR = '';

  bool isInvalidPassword = false;

  List<CWWallet> wallets = [];

  bool cwWalletsLoading = false;
  bool cwWalletsError = false;

  String? tipTo;
  bool _hasTip = false;
  bool get hasTip => _hasTip;

  void setEventServiceState(EventServiceState state) {
    eventServiceState = state;
    notifyListeners();
  }

  void setEventServiceIntentionalDisconnect(bool intentionalDisconnect) {
    eventServiceIntentionalDisconnect = intentionalDisconnect;
    notifyListeners();
  }

  void updateAmount(String amount) {
    this.amount = amount;
    notifyListeners();
  }

  void updateMessage(String message) {
    this.message = message;
    notifyListeners();
  }

  void setChainId(int chainId) {
    this.chainId = chainId;
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

  void updateCurrentWalletName(String name) {
    if (wallet != null) {
      wallet!.name = name;
      notifyListeners();
    }
  }

  void setWallet(
    CWWallet wallet,
  ) {
    this.wallet = wallet;
    notifyListeners();
  }

  void setWalletBalance(String balance) {
    if (wallet != null) {
      wallet!.setBalance(balance);
      notifyListeners();
    }
  }

  void setWalletMinter(bool minter) {
    if (wallet != null) {
      wallet!.minter = minter;
      notifyListeners();
    }
  }

  void loadWalletSuccess() {
    cleaningUp = false;
    firstLoad = false;
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

  void cleanup() {
    cleaningUp = true;
    firstLoad = true;

    transactions = [];
    isBalanceReady = false;

    loading = true;
    error = false;
    errorException = null;

    transactionsOffset = 0;
    transactionsHasMore = false;
    transactionsMaxDate = DateTime.now().toUtc();
    transactionsFromDate = DateTime.now().toUtc();

    receiveQR = '';
    walletQR = '';

    transactionSendQueue = [];
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
    isBalanceReady = false;
    notifyListeners();
  }

  void clearTemporaryTransactions({bool notify = true}) {
    transactions = transactions
        .where((element) =>
            element.state != TransactionState.sending &&
            element.state != TransactionState.pending)
        .toList();

    transactionsLoading = false;
    transactionsError = false;

    if (notify) {
      notifyListeners();
    }
  }

  void updateWalletBalanceSuccess(String balance, {bool notify = true}) {
    wallet!.setBalance(balance);

    clearTemporaryTransactions();

    loading = false;
    error = false;
    isBalanceReady = true;
    if (notify) {
      notifyListeners();
    }
  }

  void updateWalletBalanceError() {
    loading = false;
    error = true;
    isBalanceReady = true;
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
    bool hasMore = true,
    DateTime? maxDate,
  }) {
    transactionsOffset = offset;
    transactionsHasMore = hasMore;
    transactionsMaxDate = maxDate ?? DateTime.now().toUtc();
    transactionsFromDate = (transactions
                .firstWhereOrNull((t) => t.state == TransactionState.success)
                ?.date ??
            DateTime.now().toUtc())
        .subtract(const Duration(minutes: 1));
    this.transactions = [...transactions];

    clearTemporaryTransactions();

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
      {int offset = 0, bool hasMore = true}) {
    transactionsOffset = offset;
    transactionsHasMore = hasMore;
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

  void sendCallDataTransaction() {
    transactionSendLoading = true;
    transactionSendError = false;
    notifyListeners();
  }

  void sendCallDataTransactionSuccess() {
    transactionSendLoading = false;
    transactionSendError = false;
    notifyListeners();
  }

  void sendCallDataTransactionError() {
    transactionSendLoading = false;
    transactionSendError = true;
    notifyListeners();
  }

  void sendTransaction({String? id}) {
    if (id != null) {
      sendQueueRemoveTransaction(id);
    }

    setInvalidAmount(false);
    setInvalidAddress(false);
    setInvalidScanMessage(null);
    transactionSendLoading = true;
    transactionSendError = false;
    notifyListeners();
  }

  CWTransaction? inProgressTransaction;
  bool inProgressTransactionLoading = true;
  bool inProgressTransactionError = false;

  void setInProgressTransaction(CWTransaction transaction) {
    inProgressTransaction = transaction;
    inProgressTransactionLoading = true;
    inProgressTransactionError = false;
    notifyListeners();
  }

  void setInProgressTransactionError(CWTransaction transaction) {
    inProgressTransaction = transaction;
    inProgressTransactionLoading = false;
    inProgressTransactionError = true;
    transactionSendError = true;
    notifyListeners();
  }

  void clearInProgressTransaction({bool notify = false}) {
    inProgressTransaction = null;
    inProgressTransactionLoading = false;
    inProgressTransactionError = false;
    if (notify) notifyListeners();
  }

  void sendTransactionSuccess(CWTransaction? transaction) {
    if (transaction != null) {
      transactions = transactions
          .where((element) => element.id != transaction.id)
          .toList();

      transactions.insert(0, transaction);
    }

    clearTemporaryTransactions();

    transactionSendLoading = false;
    transactionSendError = false;
    notifyListeners();
  }

  void sendTransactionError() {
    transactionSendLoading = false;
    transactionSendError = true;

    inProgressTransactionError = true;
    notifyListeners();
  }

  // void incomingTransactionsRequest() {
  //   transactionsLoading = true;
  //   transactionsError = false;
  //   notifyListeners();
  // }

  bool incomingTransactionsRequestSuccess(List<CWTransaction> transactions) {
    var hasChanges = false;

    if (transactions.isNotEmpty) {
      for (final transaction in transactions) {
        final index =
            this.transactions.indexWhere((t) => t.id == transaction.id);
        if (index == -1) {
          hasChanges = true;
          this.transactions.insert(0, transaction);
        } else {
          if (this.transactions[index].state != transaction.state) {
            hasChanges = true;
          }

          this.transactions[index] = transaction;
        }
      }

      final filteredTransactions = this
          .transactions
          .where((element) => !isPendingTransactionId(element.id))
          .toList();
      if (filteredTransactions.length != this.transactions.length) {
        hasChanges = true;
      }

      transactionsFromDate = (filteredTransactions
                  .firstWhereOrNull((t) => t.state == TransactionState.success)
                  ?.date ??
              DateTime.now().toUtc())
          .subtract(const Duration(minutes: 1));

      this.transactions = filteredTransactions;
    }

    if (hasChanges) notifyListeners();

    return hasChanges;
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
    invalidScanMessage = null;
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

  void setInvalidScanMessage(String? message) {
    invalidScanMessage = message;
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
    invalidScanMessage = null;
    transactionSendError = false;

    notifyListeners();
  }

  void parseQRAddressError() {
    invalidScanMessage = 'This address seems to be invalid';
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
      invalidScanMessage = null;
    }
    notifyListeners();
  }

  void setHasAmount(bool hasAmount, bool? invalidAmount) {
    this.hasAmount = hasAmount;
    if (hasAmount || invalidAmount != null) {
      this.invalidAmount = invalidAmount ?? false;
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
    this.wallets = [...wallets];

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

  // wallet config
  Config? config;

  void setWalletConfig(Config? config) {
    this.config = config;

    notifyListeners();
  }

  // wallet account upgrade status
  bool ready = false;
  bool readyLoading = false;

  void setWalletReadyLoading(bool loading) {
    readyLoading = loading;

    notifyListeners();
  }

  void setWalletReady(bool ready) {
    this.ready = ready;
    loading = false;

    notifyListeners();
  }

  void walletActionsRequest() {
    walletActionsLoading = true;

    notifyListeners();
  }

  void walletActionsSuccess(List<ActionButton> walletActions) {
    this.walletActions = walletActions;
    walletActionsLoading = false;

    notifyListeners();
  }

  void setTipTo(String? tipTo) {
    this.tipTo = tipTo;
    notifyListeners();
  }

  void setHasTip(bool value) {
    _hasTip = value;
    notifyListeners();
  }

  void clearTipTo() {
    tipTo = null;
    _hasTip = false;
    notifyListeners();
  }
}
