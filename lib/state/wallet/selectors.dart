import 'package:citizenwallet/state/wallet/state.dart';

double selectWalletBalance(WalletState state) {
  if (state.wallet == null) {
    return 0.0;
  }

  final Map<String, String> processed = {};

  final pendingBalance =
      state.transactions.where((tx) => tx.isProcessing).fold(0.0, (sum, tx) {
    if (processed.containsKey(tx.id)) {
      return sum;
    }

    processed[tx.id] = tx.id;

    return tx.isIncoming(state.wallet!.account)
        ? sum + (double.tryParse(tx.amount) ?? 0.0)
        : sum - (double.tryParse(tx.amount) ?? 0.0);
  });

  final balance = state.wallet != null
      ? double.tryParse(state.wallet!.balance) ?? 0.0
      : 0.0;

  return balance + pendingBalance;
}

bool selectHasPendingTransactions(WalletState state) =>
    state.transactions.any((tx) => tx.isProcessing);
