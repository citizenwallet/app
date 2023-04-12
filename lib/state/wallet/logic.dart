import 'package:citizenwallet/services/web3/web3.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class WalletLogic {
  late WalletState _state;
  final Web3Service _web3 = Web3Service.fromWalletFile(
    dotenv.get('DEFAULT_RPC_URL'),
    dotenv.get('TEST_WALLET'),
    dotenv.get('TEST_WALLET_PASSWORD'),
  );

  WalletLogic(BuildContext context) {
    _state = context.read<WalletState>();
  }

  void testMethod() async {
    try {
      final transactions = await _web3.transactions;

      for (final transaction in transactions) {
        print('transaction: ');
        print(transaction.value);
        print('from: ${transaction.from}');
        print('to: ${transaction.to}');
      }

      await _web3.sendTransaction(
          to: dotenv.get('TEST_DESTINATION_ADDRESS'), amount: 100);

      // final block = await _web3.getBlock(10);
      // print(block.hashCode);
      // print(block.toString());
    } catch (e) {
      print(e);
    }
  }

  void dispose() {
    _web3.dispose();
  }
}
