import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/vouchers.dart';
import 'package:citizenwallet/services/share/share.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:web3dart/web3dart.dart';

class VoucherLogic extends WidgetsBindingObserver {
  final String password = dotenv.get('DB_VOUCHER_PASSWORD');
  final String appLinkSuffix = dotenv.get('APP_LINK_SUFFIX');

  final ConfigService _config = ConfigService();
  final DBService _db = DBService();
  final WalletService _wallet = WalletService();
  final SharingService _sharing = SharingService();

  late VoucherState _state;

  late Debounce debouncedLoad;
  List<String> toLoad = [];
  bool stopLoading = false;

  VoucherLogic(BuildContext context) {
    _state = context.read<VoucherState>();

    debouncedLoad = debounce(
      _loadVoucher,
      const Duration(milliseconds: 250),
      leading: true,
    );
  }

  void resetCreate() {
    _state.resetCreate(notify: false);
  }

  _loadVoucher() async {
    if (stopLoading) {
      return;
    }

    final toLoadCopy = [...toLoad];
    toLoad = [];

    for (final addr in toLoadCopy) {
      if (stopLoading) {
        return;
      }
      try {
        final balance = await _wallet.getBalance(addr);

        await _db.vouchers.updateBalance(addr, balance);

        _state.updateVoucherBalance(addr, balance);
        continue;
      } catch (exception) {
        //
      }

      await delay(const Duration(milliseconds: 125));
    }
  }

  Future<void> updateVoucher(String address) async {
    try {
      if (!toLoad.contains(address)) {
        toLoad.add(address);
        debouncedLoad();
      }
    } catch (exception) {
      //
    }
  }

  Future<void> fetchVouchers() async {
    try {
      _state.vouchersRequest();

      final config = await _config.config;

      final vouchers = await _db.vouchers.getAllByAlias(config.community.alias);

      _state.vouchersSuccess(vouchers
          .map(
            (e) => Voucher(
              address: e.address,
              alias: e.alias,
              name: e.name,
              balance: e.balance,
              creator: e.creator,
              createdAt: e.createdAt,
              archived: e.archived,
            ),
          )
          .toList());

      return;
    } catch (exception) {
      //
    }

    _state.vouchersError();
  }

  Future<String?> readVoucher(
    String compressedVoucher,
    String compressedVoucherParams, {
    String salt = '',
  }) async {
    try {
      _state.readVoucherRequest();

      final jsonVoucher = decompress(compressedVoucher);
      final voucherParams = decompress(compressedVoucherParams);

      final uri = Uri(query: voucherParams);

      final wallet = Wallet.fromJson(
        jsonVoucher,
        '$password$salt',
      );

      final credentials = wallet.privateKey;

      final account =
          await _wallet.getAccountAddress(credentials.address.hexEip55);

      final balance = await _wallet.getBalance(account.hexEip55);

      final voucher = Voucher(
        address: account.hexEip55,
        alias: uri.queryParameters['alias'] ?? '',
        name: uri.queryParameters['name'] ?? '',
        balance: balance,
        creator: uri.queryParameters['creator'] ?? '',
        createdAt: DateTime.now(),
        archived: true,
      );

      final dbvoucher = DBVoucher(
        address: voucher.address,
        alias: voucher.alias,
        name: voucher.name,
        balance: balance,
        voucher: jsonVoucher,
        salt: salt,
        creator: voucher.creator,
        archived: voucher.archived,
      );

      await _db.vouchers.insert(dbvoucher);

      _state.readVoucherSuccess(voucher);
      return voucher.address;
    } catch (e) {
      //
    }

    _state.readVoucherError();
    return null;
  }

  Future<Voucher?> openVoucher(String address) async {
    try {
      _state.openVoucherRequest();

      final dbvoucher = await _db.vouchers.get(address);
      if (dbvoucher == null) {
        throw Exception('voucher not found');
      }

      final balance = await _wallet.getBalance(address);

      await _db.vouchers.updateBalance(address, balance);

      final voucher = Voucher(
        address: dbvoucher.address,
        alias: dbvoucher.alias,
        name: dbvoucher.name,
        balance: balance,
        creator: dbvoucher.creator,
        createdAt: dbvoucher.createdAt,
        archived: dbvoucher.archived,
      );

      final config = await _config.config;

      final appLink = config.community.walletUrl(appLinkSuffix);

      _state.openVoucherSuccess(
          voucher,
          voucher.getLink(
            appLink,
            _wallet.currency.symbol,
            dbvoucher.voucher,
          ));

      return voucher;
    } catch (exception) {
      //
    }

    _state.openVoucherError();
    return null;
  }

  void clearOpenVoucher() {
    _state.openVoucherClear(notify: false);
  }

  Future<void> createMultipleVouchers({
    int quantity = 1,
    String? name,
    String balance = '0.0',
    String symbol = '',
    String salt = '',
  }) async {
    try {
      _state.createVoucherRequest();

      final doubleAmount = balance.replaceAll(',', '.');
      final parsedAmount = toUnit(
        doubleAmount,
        decimals: _wallet.currency.decimals,
      );

      final config = await _config.config;

      _state.createVoucherFunding();

      final List<String> addresses = [];
      final List<Uint8List> calldata = [];

      final List<DBVoucher> dbvouchers = [];
      final List<Voucher> vouchers = [];

      for (int i = 0; i < quantity; i++) {
        addresses.add(_wallet.erc20Address);

        final credentials = EthPrivateKey.createRandom(Random.secure());

        final wallet = Wallet.createNew(
          credentials,
          '$password$salt',
          Random.secure(),
          scryptN: 2,
        );

        final account =
            await _wallet.getAccountAddress(credentials.address.hexEip55);

        final dbvoucher = DBVoucher(
          address: account.hexEip55,
          alias: config.community.alias,
          name: name ?? 'Voucher for $balance $symbol',
          balance: parsedAmount.toString(),
          voucher: wallet.toJson(),
          salt: salt,
          creator: _wallet.account.hexEip55,
        );

        dbvouchers.add(dbvoucher);

        calldata.add(_wallet.erc20TransferCallData(
          account.hexEip55,
          parsedAmount,
        ));

        final voucher = Voucher(
          address: dbvoucher.address,
          alias: dbvoucher.alias,
          name: dbvoucher.name,
          balance: dbvoucher.balance,
          creator: dbvoucher.creator,
          createdAt: dbvoucher.createdAt,
          archived: dbvoucher.archived,
        );

        vouchers.add(voucher);
      }

      final (hash, userop) = await _wallet.prepareUserop(
        addresses,
        calldata,
      );

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        throw Exception('transaction failed');
      }

      for (final dbvoucher in dbvouchers) {
        await _db.vouchers.insert(dbvoucher);
      }

      _state.createVoucherMultiSuccess(
        vouchers,
      );

      return;
    } catch (exception) {
      //
    }

    _state.createVoucherError();
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

      final wallet = Wallet.createNew(
        credentials,
        '$password$salt',
        Random.secure(),
        scryptN: 2,
      );

      final doubleAmount = balance.replaceAll(',', '.');
      final parsedAmount = toUnit(
        doubleAmount,
        decimals: _wallet.currency.decimals,
      );

      final account =
          await _wallet.getAccountAddress(credentials.address.hexEip55);

      final config = await _config.config;

      final dbvoucher = DBVoucher(
        address: account.hexEip55,
        alias: config.community.alias,
        name: name ?? 'Voucher for $balance $symbol',
        balance: parsedAmount.toString(),
        voucher: wallet.toJson(),
        salt: salt,
        creator: _wallet.account.hexEip55,
      );

      await _db.vouchers.insert(dbvoucher);

      _state.createVoucherFunding();

      final calldata = _wallet.erc20TransferCallData(
        account.hexEip55,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      await _wallet.addSendingLog(
        TransferEvent(
          hash,
          '',
          0,
          DateTime.now().toUtc(),
          _wallet.account,
          account,
          parsedAmount,
          Uint8List(0),
          TransactionState.sending.name,
        ),
      );

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        await _wallet.setStatusLog(hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      await _wallet.setStatusLog(hash, TransactionState.pending);

      final voucher = Voucher(
        address: dbvoucher.address,
        alias: dbvoucher.alias,
        name: dbvoucher.name,
        balance: dbvoucher.balance,
        creator: dbvoucher.creator,
        createdAt: dbvoucher.createdAt,
        archived: dbvoucher.archived,
      );

      final appLink = config.community.walletUrl(appLinkSuffix);

      _state.createVoucherSuccess(
          voucher,
          voucher.getLink(
            appLink,
            symbol,
            dbvoucher.voucher,
          ));

      return;
    } catch (exception, stacktrace) {
      //
      print(exception);
      print(stacktrace);
    }

    _state.createVoucherError();
  }

  void shareReady() {
    _state.setShareReady();
  }

  void shareVoucher(
    String address,
    String balance,
    String symbol,
    String link,
    Rect sharePositionOrigin,
  ) async {
    try {
      final doubleAmount = balance.replaceAll(',', '.');
      final parsedAmount = double.parse(doubleAmount);

      _sharing.shareVoucher(
        parsedAmount.toStringAsFixed(2),
        link: link,
        symbol: symbol,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (exception) {
      //
    }
  }

  Future<void> returnVoucher(
    String address, {
    Function(
      BigInt amount,
      String tempId,
      String to, {
      String message,
    })? preSendingTransaction,
    Function(
      BigInt amount,
      String hash,
      String to, {
      String message,
    })? sendingTransaction,
    Function(
      BigInt amount,
      String hash,
      String to, {
      String message,
    })? pendingTransaction,
  }) async {
    try {
      _state.returnVoucherRequest();

      final voucher = await _db.vouchers.get(address);
      if (voucher == null) {
        throw Exception('voucher not found');
      }

      final credentials =
          Wallet.fromJson(voucher.voucher, '$password${voucher.salt}')
              .privateKey;

      final amount = toUnit(
        voucher.balance,
        decimals: _wallet.currency.decimals,
      );

      final tempId = '${pendingTransactionId}_${generateRandomId()}';

      if (preSendingTransaction != null) {
        preSendingTransaction(
          amount,
          tempId,
          _wallet.account.hexEip55,
        );
      }

      final calldata = _wallet.erc20TransferCallData(
        _wallet.account.hexEip55,
        amount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
        customCredentials: credentials,
      );

      final account =
          await _wallet.getAccountAddress(credentials.address.hexEip55);

      if (sendingTransaction != null) {
        sendingTransaction(
          amount,
          hash,
          _wallet.account.hexEip55,
        );
      }

      await _wallet.addSendingLog(
        TransferEvent(
          hash,
          '',
          0,
          DateTime.now().toUtc(),
          account,
          _wallet.account,
          amount,
          Uint8List(0),
          TransactionState.sending.name,
        ),
        customCredentials: credentials,
      );

      final success = await _wallet.submitUserop(
        userop,
        customCredentials: credentials,
      );
      if (!success) {
        await _wallet.setStatusLog(hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      if (pendingTransaction != null) {
        pendingTransaction(
          amount,
          hash,
          _wallet.account.hexEip55,
        );
      }

      await _wallet.setStatusLog(
        hash,
        TransactionState.pending,
        customCredentials: credentials,
      );

      await _db.vouchers.archive(address);

      _state.returnVoucherSuccess(address);
      return;
    } catch (exception) {
      //
    }

    _state.returnVoucherError();
  }

  Future<void> deleteVoucher(String address) async {
    try {
      _state.deleteVoucherRequest();

      await _db.vouchers.archive(address);

      _state.deleteVoucherSuccess(address);
      return;
    } catch (exception) {
      //
    }

    _state.returnVoucherError();
  }

  void copyVoucher(String link) {
    Clipboard.setData(ClipboardData(text: link));
  }

  void pause() {
    debouncedLoad.cancel();
    stopLoading = true;
  }

  void resume({String? address}) {
    stopLoading = false;

    if (address != null) {
      updateVoucher(address);
      return;
    }

    debouncedLoad();
  }

  void dispose() {
    resetCreate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        pause();
        break;
      default:
        resume();
    }
  }
}
