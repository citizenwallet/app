// unit tests for wallet logic and wallet state

// test group for wallet logic
import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/screens/wallets/screen.dart';
import 'package:citizenwallet/state/wallets/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../router_extension.dart';

void main() {
  group('Wallet', () {
    // test for wallet logic
    testWidgets('State Provider', (widgetTester) async {
      await widgetTester.binding.setSurfaceSize(const Size(400, 800));

      await widgetTester.pumpAppWithRouter(
        const CupertinoPageScaffold(
          child: WalletsScreen(),
        ),
      );

      await widgetTester.pumpAndSettle();

      final BuildContext context = widgetTester.element(
        find.byType(CupertinoPageScaffold),
      );

      WalletsState walletState = context.read<WalletsState>();

      walletState.clear();

      // wallet should be null at first
      expect(walletState.wallet, isNull);

      // wallets should be empty at first
      expect(walletState.wallets, isEmpty);

      // transactions should be empty at first
      expect(walletState.transactions, isEmpty);

      // populate the wallet state with a wallet
      final CWWallet wallet = CWWallet(
        1000,
        name: 'test',
        address: '0x123',
        symbol: 'ETH',
      );

      // load a wallet
      walletState.walletRequest();

      // wallet should be loading
      expect(walletState.loading, true);
      // wallet should not have an error
      expect(walletState.error, false);

      await widgetTester.pump(const Duration(milliseconds: 100));

      expect(
        reason: 'There should be an activity indicator',
        find.byKey(const Key('wallet-balance-loading')),
        findsOneWidget,
      );

      // wallet loading error
      walletState.walletError();

      await widgetTester.pump(const Duration(milliseconds: 100));

      // wallet should not be loading
      expect(walletState.loading, false);
      // wallet should have an error
      expect(walletState.error, true);

      expect(
        reason: 'There should not be an activity indicator',
        find.byKey(const Key('wallet-balance-loading')),
        findsNothing,
      );

      // wallet loading success
      walletState.walletSuccess(wallet);

      await widgetTester.pump(const Duration(milliseconds: 100));

      // wallet should not be null
      expect(walletState.wallet, isNotNull);
      // wallet should not be loading
      expect(walletState.loading, false);
      // wallet should not have an error
      expect(walletState.error, false);

      expect(
        reason: 'There should not be an activity indicator',
        find.byKey(const Key('wallet-balance-loading')),
        findsNothing,
      );

      expect(
        reason: 'There should balance text displayed',
        find.byKey(const Key('wallet-balance')),
        findsOneWidget,
      );

      expect(
        reason: 'The balance amount should match the wallet amount',
        find.byWidgetPredicate((widget) {
          if (widget is Text && widget.key == const Key('wallet-balance')) {
            return widget.data == walletState.wallet!.formattedBalance;
          }

          return false;
        }),
        findsOneWidget,
      );

      // populate the wallet state with a list of wallets
      final List<CWWallet> wallets = [
        CWWallet(
          30,
          name: 'test',
          address: '0x123',
          symbol: 'ETH',
        ),
        CWWallet(
          10,
          name: 'test',
          address: '0x456',
          symbol: 'BTC',
        ),
      ];

      // wallets loading request
      walletState.walletListRequest();

      // wallets should be loading
      expect(walletState.loadingWallets, true);
      // wallets should not have an error
      expect(walletState.errorWallets, false);

      // wallets loading error
      walletState.walletListError();

      // wallets should not be loading
      expect(walletState.loadingWallets, false);
      // wallets should have an error
      expect(walletState.errorWallets, true);

      // wallets loading success
      walletState.walletListSuccess(wallets);

      // wallets should not be loading
      expect(walletState.loadingWallets, false);
      // wallets should not have an error
      expect(walletState.errorWallets, false);

      // populate the wallet state with a list of transactions
      final List<CWTransaction> transactions = [
        CWTransaction(
          1000,
          id: '0',
          chainId: 1,
          from: '0x123',
          to: '0x456',
          title: 'test',
          date: DateTime.now(),
        ),
        CWTransaction(
          1000,
          id: '1',
          chainId: 1,
          from: '0x123',
          to: '0x456',
          title: 'test',
          date: DateTime.now(),
        ),
      ];

      // transactions loading request
      walletState.transactionListRequest();

      // transactions should be loading
      expect(walletState.loadingTransactions, true);
      // transactions should not have an error
      expect(walletState.errorTransactions, false);

      // transactions loading error
      walletState.transactionListError();

      // transactions should not be loading
      expect(walletState.loadingTransactions, false);
      // transactions should have an error
      expect(walletState.errorTransactions, true);

      // transactions loading success
      walletState.transactionListSuccess(transactions);

      // transactions should not be loading
      expect(walletState.loadingTransactions, false);
      // transactions should not have an error
      expect(walletState.errorTransactions, false);

      await widgetTester.pumpAndSettle();

      // read the current wallet from state
      walletState = context.read<WalletsState>();

      // test that the wallet state is populated with the correct wallet
      expect(walletState.wallet, wallet);

      // test that the wallet state is populated with the correct wallets
      expect(walletState.wallets, wallets);

      // test that the wallet state is populated with the correct transactions
      expect(walletState.transactions, transactions);

      // resets the screen to its original size after the test end
      addTearDown(widgetTester.binding.window.clearPhysicalSizeTestValue);
    });
  });
}
