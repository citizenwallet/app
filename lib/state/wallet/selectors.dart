import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/currency.dart';

double selectWalletBalance(WalletState state) {
  final pendingOutgoingBalance = state.transactions
      .where((tx) =>
          tx.isProcessing &&
          state.wallet != null &&
          !tx.isIncoming(state.wallet!.account))
      .fold(0.0, (sum, tx) => sum + (double.tryParse(tx.amount) ?? 0.0));

  final pendingIncomingBalance = state.transactions
      .where((tx) =>
          tx.isProcessing &&
          state.wallet != null &&
          tx.isIncoming(state.wallet!.account))
      .fold(0.0, (sum, tx) => sum + (double.tryParse(tx.amount) ?? 0.0));

  final balance = state.wallet != null
      ? double.tryParse(state.wallet!.balance) ?? 0.0
      : 0.0;

  return balance - pendingOutgoingBalance + pendingIncomingBalance;
}

bool selectHasPendingTransactions(WalletState state) =>
    state.transactions.any((tx) => tx.isProcessing);
