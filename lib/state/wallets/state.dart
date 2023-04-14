import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:flutter/cupertino.dart';

class WalletsState extends ChangeNotifier {
  CWWallet? wallet;
  bool loading = false;
  bool error = false;

  List<CWWallet> wallets = [];
  bool loadingWallets = false;
  bool errorWallets = false;

  List<CWTransaction> transactions = [];
  bool loadingTransactions = false;
  bool errorTransactions = false;

  void walletRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void walletSuccess(CWWallet wallet) {
    this.wallet = wallet;
    loading = false;
    error = false;
    notifyListeners();
  }

  void walletError() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void walletListRequest() {
    loadingWallets = true;
    errorWallets = false;
    notifyListeners();
  }

  void walletListSuccess(List<CWWallet> wallets) {
    this.wallets.clear();
    this.wallets.addAll(wallets);
    loadingWallets = false;
    errorWallets = false;
    notifyListeners();
  }

  void walletListError() {
    loadingWallets = false;
    errorWallets = true;
    notifyListeners();
  }

  void transactionListRequest() {
    loadingTransactions = true;
    errorTransactions = false;
    notifyListeners();
  }

  void transactionListSuccess(List<CWTransaction> transactions) {
    this.transactions.clear();
    this.transactions.addAll(transactions);
    loadingTransactions = false;
    errorTransactions = false;
    notifyListeners();
  }

  void transactionListError() {
    loadingTransactions = false;
    errorTransactions = true;
    notifyListeners();
  }

  void clear() {
    wallet = null;
    loading = false;
    error = false;
    wallets.clear();
    loadingWallets = false;
    errorWallets = false;
    transactions.clear();
    loadingTransactions = false;
    errorTransactions = false;
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
