import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/account/db.dart';
import 'package:citizenwallet/services/db/account/vouchers.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/share/share.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/engine/utils.dart';
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
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class VoucherLogic extends WidgetsBindingObserver {
  final String password = dotenv.get('DB_VOUCHER_PASSWORD');
  final String deepLinkURL = dotenv.get('ORIGIN_HEADER');

  final AppDBService _appDBService = AppDBService();
  final AccountDBService _accountDBService = AccountDBService();
  final SharingService _sharing = SharingService();

  late EthPrivateKey _currentCredentials;
  late EthereumAddress _currentAccount;
  late Config _currentConfig;

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

  void setWalletState(
      Config config, EthPrivateKey credentials, EthereumAddress account) {
    _currentConfig = config;
    _currentCredentials = credentials;
    _currentAccount = account;
  }

  void resetCreate() {
    _state.resetCreate(notify: false);
  }

  _loadVoucher() async {
    if (stopLoading) {
      return;
    }

    if (_currentConfig == null) {
      return;
    }

    final toLoadCopy = [...toLoad];
    toLoad = [];

    for (final addr in toLoadCopy) {
      if (stopLoading) {
        return;
      }
      try {
        final balance =
            await getBalance(_currentConfig, EthereumAddress.fromHex(addr));

        await _accountDBService.vouchers
            .updateBalance(addr, balance.toString());

        _state.updateVoucherBalance(addr, balance.toString());
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

      if (_currentConfig == null) {
        throw Exception('wallet not initialized');
      }

      final vouchers = await _accountDBService.vouchers
          .getAllByAlias(_currentConfig.community.alias);

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
              legacy: e.legacy,
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

      final EthPrivateKey credentials;
      if (jsonVoucher.startsWith('v2-')) {
        credentials =
            EthPrivateKey.fromHex(jsonVoucher.replaceFirst('v2-', ''));
      } else {
        // legacy voucher format
        final wallet = Wallet.fromJson(
          jsonVoucher,
          '$password$salt',
        );
        credentials = wallet.privateKey;
      }

      EthereumAddress account = uri.queryParameters['account'] != null
          ? EthereumAddress.fromHex(uri.queryParameters['account']!)
          : await getAccountAddress(
              _currentConfig,
              credentials.address.hexEip55,
              legacy: true,
              cache: false,
            );

      final balance =
          await getBalance(_currentConfig ?? Config.fromJson({}), account);

      final voucher = Voucher(
        address: account.hexEip55,
        alias: uri.queryParameters['alias'] ?? '',
        name: uri.queryParameters['name'] ?? '',
        balance: balance,
        creator: uri.queryParameters['creator'] ?? '',
        createdAt: DateTime.now(),
        archived: true,
        legacy: uri.queryParameters['account'] == null,
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
        legacy: voucher.legacy,
      );

      await _accountDBService.vouchers.insert(dbvoucher);

      _state.readVoucherSuccess(voucher);
      return voucher.address;
    } catch (_) {
      //
    }

    _state.readVoucherError();
    return null;
  }

  Future<Voucher?> openVoucher(String address) async {
    try {
      _state.openVoucherRequest();

      final dbvoucher = await _accountDBService.vouchers.get(address);
      if (dbvoucher == null) {
        throw Exception('voucher not found');
      }

      final balance =
          await getBalance(_currentConfig, EthereumAddress.fromHex(address));

      await _accountDBService.vouchers.updateBalance(address, balance);

      final voucher = Voucher(
        address: dbvoucher.address,
        alias: dbvoucher.alias,
        name: dbvoucher.name,
        balance: balance,
        creator: dbvoucher.creator,
        createdAt: dbvoucher.createdAt,
        archived: dbvoucher.archived,
        legacy: dbvoucher.legacy,
      );

      if (_currentConfig.community.alias.isEmpty) {
        throw Exception('alias not found');
      }

      final community =
          await _appDBService.communities.get(_currentConfig.community.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final appLink = communityConfig.community.walletUrl(deepLinkURL);

      _state.openVoucherSuccess(
        voucher,
        voucher.getLink(
          appLink,
          _currentConfig.getPrimaryToken().symbol,
          dbvoucher.voucher,
        ),
      );

      return voucher;
    } catch (_) {
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
        decimals: _currentConfig.getPrimaryToken().decimals,
      );

      if (_currentConfig.community.alias.isEmpty) {
        throw Exception('alias not found');
      }

      final community =
          await _appDBService.communities.get(_currentConfig.community.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      // _state.createVoucherFunding();

      final List<String> addresses = [];
      final List<Uint8List> calldata = [];

      final List<DBVoucher> dbvouchers = [];
      final List<Voucher> vouchers = [];

      for (int i = 0; i < quantity; i++) {
        addresses.add(_currentConfig.getPrimaryToken().address);

        final credentials = EthPrivateKey.createRandom(Random.secure());

        final wallet = Wallet.createNew(
          credentials,
          '$password$salt',
          Random.secure(),
          scryptN: 2,
        );

        final account = await getAccountAddress(
            _currentConfig, credentials.address.hexEip55);

        final dbvoucher = DBVoucher(
          address: account.hexEip55,
          alias: communityConfig.community.alias,
          name: name ?? 'Voucher for $balance $symbol',
          balance: parsedAmount.toString(),
          voucher: wallet.toJson(),
          salt: salt,
          creator: _currentAccount.hexEip55,
          legacy: false,
        );

        dbvouchers.add(dbvoucher);

        // TODO: token id should be set
        calldata.add(tokenTransferCallData(
          _currentConfig,
          _currentAccount,
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
          legacy: dbvoucher.legacy,
        );

        vouchers.add(voucher);
      }

      final (_, userop) = await prepareUserop(
        _currentConfig,
        _currentAccount,
        _currentCredentials,
        addresses,
        calldata,
      );

      final txHash = await submitUserop(
        _currentConfig,
        userop,
      );
      if (txHash == null) {
        throw Exception('transaction failed');
      }

      final success = await waitForTxSuccess(_currentConfig, txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      for (final dbvoucher in dbvouchers) {
        await _accountDBService.vouchers.insert(dbvoucher);
      }

      _state.createVoucherMultiSuccess(
        vouchers,
      );

      return;
    } catch (_) {
      //
    }

    _state.createVoucherError();
  }

  Future<void> createVoucher({
    String? name,
    String balance = '0.0',
    String symbol = '',
    String salt = '',
    bool mint = false,
  }) async {
    try {
      _state.createVoucherRequest();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final doubleAmount = balance.replaceAll(',', '.');
      final parsedAmount = toUnit(
        doubleAmount,
        decimals: _currentConfig.getPrimaryToken().decimals,
      );

      final account = await getAccountAddress(
          _currentConfig, credentials.address.hexEip55);

      if (_currentConfig.community.alias.isEmpty) {
        throw Exception('alias not found');
      }

      final community =
          await _appDBService.communities.get(_currentConfig.community.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final dbvoucher = DBVoucher(
        address: account.hexEip55,
        alias: communityConfig.community.alias,
        name: name ?? 'Voucher for $balance $symbol',
        balance: parsedAmount.toString(),
        voucher: 'v2-${bytesToHex(credentials.privateKey)}',
        salt: salt,
        creator: _currentAccount.hexEip55,
        legacy: false,
      );

      await _accountDBService.vouchers.insert(dbvoucher);

      // TODO: token id should be set
      final calldata = mint
          ? tokenMintCallData(
              _currentConfig,
              account.hexEip55,
              parsedAmount,
            )
          : tokenTransferCallData(
              _currentConfig,
              _currentAccount,
              account.hexEip55,
              parsedAmount,
            );

      final (_, userop) = await prepareUserop(
        _currentConfig,
        _currentAccount,
        _currentCredentials,
        [_currentConfig.getPrimaryToken().address],
        [calldata],
      );

      final args = {
        'from': _currentAccount.hexEip55,
        'to': account.hexEip55,
      };
      if (_currentConfig.getPrimaryToken().standard == 'erc1155') {
        args['operator'] = _currentAccount.hexEip55;
        args['id'] = '0';
        args['amount'] = parsedAmount.toString();
      } else {
        args['value'] = parsedAmount.toString();
      }

      final eventData = createEventData(
        stringSignature: transferEventStringSignature(_currentConfig),
        topic: transferEventSignature(_currentConfig),
        args: args,
      );

      final txHash = await submitUserop(
        _currentConfig,
        userop,
        data: eventData,
        extraData: TransferData(dbvoucher.name),
      );
      if (txHash == null) {
        throw Exception('transaction failed');
      }

      final voucher = Voucher(
        address: dbvoucher.address,
        alias: dbvoucher.alias,
        name: dbvoucher.name,
        balance: dbvoucher.balance,
        creator: dbvoucher.creator,
        createdAt: dbvoucher.createdAt,
        archived: dbvoucher.archived,
        legacy: false,
      );

      final appLink = communityConfig.community.walletUrl(deepLinkURL);

      _state.createVoucherFunding(
        voucher,
        voucher.getLink(
          appLink,
          symbol,
          dbvoucher.voucher,
        ),
      );

      final success = await waitForTxSuccess(_currentConfig, txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      _state.createVoucherSuccess(
        voucher,
      );
      return;
    } catch (_) {}

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
      String to,
      String from, {
      String message,
    })? preSendingTransaction,
    Function(
      BigInt amount,
      String hash,
      String to,
      String from, {
      String message,
    })? sendingTransaction,
  }) async {
    try {
      _state.returnVoucherRequest();

      final voucher = await _accountDBService.vouchers.get(address);
      if (voucher == null) {
        throw Exception('voucher not found');
      }

      final jsonVoucher = voucher.voucher;

      final EthPrivateKey credentials;
      if (jsonVoucher.startsWith('v2-')) {
        credentials =
            EthPrivateKey.fromHex(jsonVoucher.replaceFirst('v2-', ''));
      } else {
        // legacy voucher format
        final wallet = Wallet.fromJson(
          jsonVoucher,
          '$password${voucher.salt}',
        );
        credentials = wallet.privateKey;
      }

      final amount = BigInt.parse(voucher.balance);

      final tempId = '${pendingTransactionId}_${generateRandomId()}';

      if (preSendingTransaction != null) {
        preSendingTransaction(
            amount, tempId, _currentAccount.hexEip55, voucher.address);
      }

      final calldata = tokenTransferCallData(
        _currentConfig,
        _currentAccount,
        voucher.address,
        amount,
      );

      final (hash, userop) = await prepareUserop(
        _currentConfig,
        _currentAccount,
        _currentCredentials,
        [_currentConfig.getPrimaryToken().address],
        [calldata],
        customCredentials: credentials,
      );

      if (sendingTransaction != null) {
        sendingTransaction(
            amount, hash, _currentAccount.hexEip55, voucher.address);
      }

      final args = {
        'from': voucher.address,
        'to': _currentAccount.hexEip55,
      };
      if (_currentConfig.getPrimaryToken().standard == 'erc1155') {
        args['operator'] = voucher.address;
        args['id'] = '0';
        args['amount'] = amount.toString();
      } else {
        args['value'] = amount.toString();
      }

      final eventData = createEventData(
        stringSignature: transferEventStringSignature(_currentConfig),
        topic: transferEventSignature(_currentConfig),
        args: args,
      );

      final txHash = await submitUserop(
        _currentConfig,
        userop,
        customCredentials: credentials,
        data: eventData,
        extraData: voucher.name.isNotEmpty ? TransferData(voucher.name) : null,
      );
      if (txHash == null) {
        throw Exception('transaction failed');
      }

      final success = await waitForTxSuccess(_currentConfig, txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      await _accountDBService.vouchers.archive(address);

      _state.returnVoucherSuccess(address);
      return;
    } catch (_) {
      //
    }

    _state.returnVoucherError();
  }

  Future<void> deleteVoucher(String address) async {
    try {
      _state.deleteVoucherRequest();

      await _accountDBService.vouchers.archive(address);

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
