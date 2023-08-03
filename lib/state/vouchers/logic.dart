import 'dart:math';

import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class VoucherLogic {
  final String password = dotenv.get('DB_VOUCHER_PASSWORD');
  late VoucherState _state;

  VoucherLogic(BuildContext context) {
    _state = context.read<VoucherState>();
  }

  void resetCreate() {
    _state.resetCreate();
  }

  Future<void> createVoucher(
      {String name = '', String balance = '0.0', String salt = ''}) async {
    try {
      _state.createVoucherRequest();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final wallet =
          Wallet.createNew(credentials, '$password$salt', Random.secure());

      await delay(const Duration(seconds: 1));

      _state.createVoucherFunding();

      await delay(const Duration(seconds: 1));

      final voucher = Voucher(
        address: credentials.address.hexEip55,
        name: name,
        balance: balance,
        createdAt: DateTime.now(),
      );

      _state.createVoucherSuccess(voucher);

      return;
    } catch (exception) {
      //
    }

    _state.createVoucherError();
  }
}
