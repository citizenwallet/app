import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:collection/collection.dart';

double selectWalletBalance(WalletState state) {
  if (state.wallet == null) {
    return 0.0;
  }

  final Map<String, String> processed = {};

  final pendingBalance =
      state.transactions.where((tx) => tx.isProcessing).fold(0.0, (sum, tx) {
    if (processed.containsKey(tx.hash)) {
      return sum;
    }

    processed[tx.hash] = tx.hash;

    return tx.isIncoming(state.wallet!.account)
        ? sum + (double.tryParse(tx.amount) ?? 0.0)
        : sum - (double.tryParse(tx.amount) ?? 0.0);
  });

  final balance = state.wallet != null
      ? double.tryParse(state.wallet!.balance) ?? 0.0
      : 0.0;

  return balance + pendingBalance;
}

// selectShouldBlockSending returns true if there is a pending transaction that is outgoing
bool selectShouldBlockSending(WalletState state) {
  if (state.wallet == null) {
    return true;
  }
  if (!state.ready) {
    return true;
  }

  if (state.wallet?.doubleBalance == 0.0 &&
      state.config!.getTopUpPlugin() == null) {
    return true;
  }

  if (state.config?.online == false) {
    return true;
  }

  return false;
}

bool selectHasProcessingTransactions(WalletState state) =>
    state.transactions.any((tx) => tx.isProcessing);

List<CWWallet> selectSortedWalletsByAlias(WalletState state) =>
    state.wallets.toList()
      ..sort((a, b) => a.alias.toLowerCase().compareTo(b.alias.toLowerCase()));

Map<String, List<CWWallet>> selectSortedGroupedWalletsByAlias(
        WalletState state) =>
    state.wallets
        .where((w) {
          final wallet = state.wallet;
          if (wallet == null) {
            return true;
          }

          return '${w.alias}:${w.account}' !=
              '${wallet.alias}:${wallet.account}';
        })
        .sortedBy((w) => w.alias.toLowerCase())
        .groupListsBy((w) => w.alias.toLowerCase());

ActionButton? selectActionButtonToShow(WalletState state) {
  if (state.walletActions.isEmpty) {
    return null;
  }

  final moreButton = state.walletActions.firstWhereOrNull(
    (action) => action.buttonType == ActionButtonType.more,
  );

  if (moreButton != null) {
    return moreButton;
  }

  return state.walletActions.last;
}
