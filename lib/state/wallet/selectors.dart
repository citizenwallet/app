import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/currency.dart';

String selectWalletBalance(WalletState state) {
  final pendingBalance = state.transactions
      .where((tx) => tx.isProcessing)
      .fold(0.0, (sum, tx) => sum + (double.tryParse(tx.amount) ?? 0.0));

  final balance = state.wallet != null
      ? double.tryParse(state.wallet!.balance) ?? 0.0
      : 0.0;

  final total = balance - pendingBalance;

  return formatAmount(total > 0 ? total : 0.0,
      decimalDigits: state.wallet != null ? state.wallet!.decimalDigits : 2);
}

bool selectHasPendingTransactions(WalletState state) =>
    state.transactions.any((tx) => tx.isProcessing);
