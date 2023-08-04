import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/vouchers.dart';
import 'package:citizenwallet/services/share/share.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class VoucherLogic {
  final String password = dotenv.get('DB_VOUCHER_PASSWORD');
  final String appLink = dotenv.get('APP_LINK');

  final DBService _db = DBService();
  final WalletService _wallet = WalletService();
  final SharingService _sharing = SharingService();

  late VoucherState _state;

  VoucherLogic(BuildContext context) {
    _state = context.read<VoucherState>();
  }

  void resetCreate() {
    _state.resetCreate(notify: false);
  }

  Future<void> fetchVouchers(String token) async {
    try {
      _state.vouchersRequest();

      final vouchers = await _db.vouchers.getAllByToken(token);

      _state.vouchersSuccess(vouchers
          .map(
            (e) => Voucher(
              address: e.address,
              token: e.token,
              name: e.name,
              balance: e.balance,
              createdAt: e.createdAt,
            ),
          )
          .toList());

      return;
    } catch (exception) {
      //
    }

    _state.vouchersError();
  }

  Future<void> createVoucher({
    String? name,
    String balance = '0.0',
    String symbol = '',
    String salt = '',
  }) async {
    try {
      _state.createVoucherRequest();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final wallet =
          Wallet.createNew(credentials, '$password$salt', Random.secure());

      final doubleAmount = balance.replaceAll(',', '.');
      final parsedAmount = double.parse(doubleAmount) * 1000;

      final dbvoucher = DBVoucher(
        address: credentials.address.hexEip55,
        token: _wallet.erc20Address,
        name: name ?? 'Voucher for $parsedAmount $symbol',
        balance: '$parsedAmount',
        voucher: wallet.toJson(),
        salt: salt,
      );

      await _db.vouchers.insert(dbvoucher);

      _state.createVoucherFunding();

      final calldata = _wallet.erc20TransferCallData(
        credentials.address.hexEip55,
        BigInt.from(double.parse(doubleAmount) * 1000),
      );

      final (hash, userop) = await _wallet.prepareUserop(
        _wallet.erc20Address,
        calldata,
      );

      final tx = await _wallet.addSendingLog(
        TransferEvent(
          hash,
          '',
          0,
          DateTime.now().toUtc(),
          _wallet.account,
          credentials.address,
          EtherAmount.fromBigInt(
            EtherUnit.kwei,
            BigInt.from(double.parse(doubleAmount) * 1000),
          ).getInWei,
          Uint8List(0),
          TransactionState.sending.name,
        ),
      );
      if (tx == null) {
        throw Exception('failed to send log');
      }

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        await _wallet.setStatusLog(tx.hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      await _wallet.setStatusLog(tx.hash, TransactionState.pending);

      final voucher = Voucher(
        address: dbvoucher.address,
        token: dbvoucher.token,
        name: dbvoucher.name,
        balance: dbvoucher.balance,
        createdAt: dbvoucher.createdAt,
      );

      _state.createVoucherSuccess(
          voucher,
          voucher.getLink(
            appLink,
            symbol,
            dbvoucher.voucher,
          ));

      return;
    } catch (exception) {
      //
    }

    _state.createVoucherError();
  }

  void shareReady() {
    _state.setShareReady();
  }

  void shareVoucher(
    String address,
    String symbol,
    Rect sharePositionOrigin,
  ) async {
    try {
      if (_state.createdVoucher == null) {
        throw Exception('voucher not found');
      }

      final doubleAmount = _state.createdVoucher!.balance.replaceAll(',', '.');
      final parsedAmount = double.parse(doubleAmount) / 1000;

      _sharing.shareVoucher(
        '$parsedAmount',
        link: _state.shareLink,
        symbol: symbol,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (exception) {
      //
    }
  }

  void copyVoucher() {
    Clipboard.setData(ClipboardData(text: _state.shareLink));
  }

  void dispose() {
    resetCreate();
  }
}
