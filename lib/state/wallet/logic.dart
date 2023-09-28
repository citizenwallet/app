import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/cache/contacts.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/transactions.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

const txFetchInterval = Duration(seconds: 1);

class QREmptyException implements Exception {
  final String message = 'This QR code seems to be empty';

  QREmptyException();
}

class QRInvalidException implements Exception {
  final String message = 'This QR code seems to be invalid';

  QRInvalidException();
}

class QRAliasMismatchException implements Exception {
  final String message = 'This QR code is from a different community';

  QRAliasMismatchException();
}

class QRMissingAddressException implements Exception {
  final String message = 'This QR code is has no receive address';

  QRMissingAddressException();
}

class WalletLogic extends WidgetsBindingObserver {
  bool get isWalletLoaded => _state.wallet != null;
  late WalletState _state;

  final String appLinkSuffix = dotenv.get('APP_LINK_SUFFIX');

  final ConfigService _config = ConfigService();
  final WalletService _wallet = WalletService();
  final DBService _db = DBService();

  final PreferencesService _preferences = PreferencesService();
  final EncryptedPreferencesService _encPrefs =
      getEncryptedPreferencesService();

  bool cancelLoadAccounts = false;
  String? _fetchRequest;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TextEditingController get addressController => _addressController;
  TextEditingController get amountController => _amountController;
  TextEditingController get messageController => _messageController;

  String? get lastWallet => _preferences.lastWallet;
  String get address => _wallet.address.hexEip55;
  String get token => _wallet.erc20Address;

  WalletLogic(BuildContext context) {
    _state = context.read<WalletState>();
  }

  EthPrivateKey get privateKey {
    return _wallet.credentials;
  }

  Future<void> resetWalletPreferences() async {
    try {
      await _preferences.clear();

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> fetchWalletConfig() async {
    try {
      // on web, use host
      _config.initWeb(
        dotenv.get('APP_LINK_SUFFIX'),
      );

      final config = await _config.config;

      _state.setWalletConfig(config);

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> openWalletFromURL(
    String encodedWallet,
    String password,
    String alias,
    Future<void> Function() loadAdditionalData,
  ) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final decoded = encodedWallet.startsWith('v2-')
          ? convertUint8ListToString(
              base64Decode(encodedWallet.replaceFirst('v2-', '')))
          : jsonEncode(
              QR.fromCompressedJson(encodedWallet).toQRWallet().data.wallet);

      await delay(const Duration(milliseconds: 0));

      Wallet cred = Wallet.fromJson(decoded, password);

      await delay(const Duration(milliseconds: 0));

      // on web, use host
      _config.initWeb(
        dotenv.get('APP_LINK_SUFFIX'),
      );

      final config = await _config.config;

      await _wallet.init(
        bytesToHex(cred.privateKey.privateKey),
        NativeCurrency(
          name: config.token.name,
          symbol: config.token.symbol,
          decimals: config.token.decimals,
        ),
        config,
      );

      await _db.init('wallet_${_wallet.address.hexEip55}');

      ContactsCache().init(_db);

      final balance = await _wallet.balance;
      final currency = _wallet.currency;

      _state.setWalletConfig(config);

      _state.setWallet(
        CWWallet(
          balance,
          name:
              'Citizen Wallet', // on web, acts as a page's title, wallet is fitting here
          address: _wallet.address.hexEip55,
          alias: config.community.alias,
          account: _wallet.account.hexEip55,
          currencyName: config.token.name,
          symbol: config.token.symbol,
          currencyLogo: config.community.logo,
          decimalDigits: currency.decimals,
          locked: false,
        ),
      );

      await loadAdditionalData();

      await _preferences.setLastWallet(_wallet.address.hexEip55);
      await _preferences.setLastAlias(config.community.alias);
      await _preferences.setLastWalletLink(encodedWallet);

      _state.loadWalletSuccess();

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadWalletError();
    return false;
  }

  /// openWallet opens a wallet given an address and also loads additional data
  ///
  /// if a wallet is already loaded, it only fetches additional data
  Future<String?> openWallet(
    String? paramAddress,
    String? paramAlias,
    Future<void> Function(bool hasChanged) loadAdditionalData,
  ) async {
    try {
      final String? address = paramAddress ?? _preferences.lastWallet;
      final String alias = paramAlias ?? _preferences.lastAlias ?? 'app';

      if (address == null) {
        throw Exception('address not found');
      }

      // on native, use env
      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      if (isWalletLoaded &&
          paramAlias == alias &&
          paramAddress == _wallet.address.hexEip55) {
        final balance = await _wallet.balance;

        _state.updateWalletBalanceSuccess(balance);

        _state.loadWalletSuccess();

        await loadAdditionalData(false);

        await _preferences.setLastWallet(address);
        await _preferences.setLastAlias(alias);

        return address;
      }

      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _encPrefs.getWalletBackup(address, alias);

      if (dbWallet == null || dbWallet.privateKey.isEmpty) {
        throw NotFoundException();
      }

      await _wallet.init(
        dbWallet.privateKey,
        NativeCurrency(
          name: config.token.name,
          symbol: config.token.symbol,
          decimals: config.token.decimals,
        ),
        config,
      );

      await _db.init('wallet_${_wallet.address.hexEip55}');

      ContactsCache().init(_db);

      final balance = await _wallet.balance;
      final currency = _wallet.currency;

      _state.setWalletConfig(config);

      _state.setWallet(
        CWWallet(
          balance,
          name: dbWallet.name,
          address: _wallet.address.hexEip55,
          alias: dbWallet.alias,
          account: _wallet.account.hexEip55,
          currencyName: config.token.name,
          symbol: config.token.symbol,
          currencyLogo: config.community.logo,
          decimalDigits: currency.decimals,
          locked: dbWallet.privateKey.isEmpty,
        ),
      );

      _state.loadWalletSuccess();

      await loadAdditionalData(true);

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

      return address;
    } on NotFoundException {
      _state.loadWalletError(exception: NotFoundException());

      Sentry.captureException(
        NotFoundException(),
      );

      return null;
    } catch (exception, stackTrace) {
      print(exception);
      print(stackTrace);
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadWalletError();
    return null;
  }

  Future<String?> createWallet(String alias) async {
    try {
      _state.createWallet();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final address = credentials.address.hexEip55;

      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      _state.setWalletConfig(config);

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: 'New ${config.token.symbol} Account',
        address: address,
        alias: config.community.alias,
        account: '',
        currencyName: config.token.name,
        symbol: config.token.symbol,
        currencyLogo: config.community.logo,
        locked: false,
      );

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: bytesToHex(credentials.privateKey),
        name: 'New ${config.token.symbol} Account',
        alias: config.community.alias,
      ));

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

      _state.createWalletSuccess(
        cwwallet,
      );

      return credentials.address.hexEip55;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.createWalletError();

    return null;
  }

  Future<String?> importWallet(String qrWallet, String alias) async {
    try {
      _state.createWallet();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (isPrivateKey) {
        final credentials = stringToPrivateKey(qrWallet);
        if (credentials == null) {
          throw Exception('Invalid private key');
        }

        final address = credentials.address.hexEip55;

        _config.init(
          dotenv.get('WALLET_CONFIG_URL'),
          alias,
        );

        final config = await _config.config;

        final name = 'Imported ${config.token.symbol} Account';

        _state.setWalletConfig(config);

        final CWWallet cwwallet = CWWallet(
          '0.0',
          name: name,
          address: address,
          alias: config.community.alias,
          account: '',
          currencyName: config.token.name,
          symbol: config.token.symbol,
          currencyLogo: config.community.logo,
          locked: false,
        );

        await _encPrefs.setWalletBackup(BackupWallet(
          address: address,
          privateKey: bytesToHex(credentials.privateKey),
          name: name,
          alias: config.community.alias,
        ));

        await _preferences.setLastWallet(address);
        await _preferences.setLastAlias(config.community.alias);

        _state.createWalletSuccess(cwwallet);

        return address;
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = EthereumAddress.fromHex(wallet.data.address).hexEip55;

      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      final name = 'Imported ${config.token.symbol} Account';

      _state.setWalletConfig(config);

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: address,
        alias: config.community.alias,
        account: '',
        currencyName: config.token.name,
        symbol: config.token.symbol,
        currencyLogo: config.community.logo,
        locked: false,
      );

      // TODO: fix this, not sure if we can extract the private key from the wallet json like this
      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: bytesToHex(wallet.data.wallet['privateKey']),
        name: name,
        alias: config.community.alias,
      ));

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

      _state.createWalletSuccess(cwwallet);

      return address;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.createWalletError();

    return null;
  }

  Future<void> editWallet(String address, String name) async {
    try {
      final config = await _config.config;

      final dbWallet =
          await _encPrefs.getWalletBackup(address, config.community.alias);
      if (dbWallet == null) {
        throw NotFoundException();
      }

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: dbWallet.privateKey,
        name: name,
        alias: dbWallet.alias,
      ));

      loadDBWallets();

      _state.updateCurrentWalletName(name);

      return;
    } on NotFoundException {
      // HANDLE
      Sentry.captureException(
        NotFoundException(),
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.createWalletError();
  }

  void transferEventSubscribe() async {
    try {
      _fetchRequest = generateRandomId();

      fetchNewTransfers(_fetchRequest);

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  void transferEventUnsubscribe() {
    _fetchRequest = null;
  }

  void fetchNewTransfers(String? id) async {
    try {
      if (_fetchRequest == null || _fetchRequest != id) {
        // make sure that we only have one request at a time
        return;
      }

      final txs =
          await _wallet.fetchNewErc20Transfers(_state.transactionsFromDate);

      if (txs == null) {
        // unsuccessful and there's nothing

        // still keep balance up to date no matter what
        updateBalance();

        await delay(txFetchInterval);

        fetchNewTransfers(id);
        return;
      }

      if (txs.isEmpty) {
        // successful but there's nothing

        // still keep balance up to date no matter what
        updateBalance();

        await delay(txFetchInterval);

        fetchNewTransfers(id);
        return;
      }

      final cwtransactions = txs.map(
        (tx) => CWTransaction(
          fromDoubleUnit(
            tx.value.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: tx.hash,
          hash: tx.txhash,
          chainId: _wallet.chainId,
          from: tx.from.hexEip55,
          to: tx.to.hexEip55,
          title: '',
          date: tx.createdAt,
          state: TransactionState.values.firstWhereOrNull(
                (v) => v.name == tx.status,
              ) ??
              TransactionState.success,
        ),
      );

      final iterableRemoteTxs = txs.map(
        (tx) => DBTransaction(
          hash: tx.hash,
          txHash: tx.txhash,
          tokenId: tx.tokenId,
          createdAt: tx.createdAt,
          from: tx.from.hexEip55,
          to: tx.to.hexEip55,
          nonce: 0, // TODO: remove nonce hardcode
          value: tx.value.toInt(),
          data: '',
          status: tx.status,
          contract: _wallet.erc20Address,
        ),
      );

      await _db.transactions.insertAll(
        iterableRemoteTxs.toList(),
      );

      final hasChanges = _state.incomingTransactionsRequestSuccess(
        cwtransactions.toList(),
      );

      if (hasChanges) {
        updateBalance();
      }

      await delay(txFetchInterval);

      fetchNewTransfers(id);
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.incomingTransactionsRequestError();
    await delay(txFetchInterval);

    fetchNewTransfers(id);
  }

  // takes a password and returns a wallet
  Future<String?> returnWallet(String address, String alias) async {
    try {
      final dbWallet = await _encPrefs.getWalletBackup(address, alias);
      if (dbWallet == null) {
        throw NotFoundException();
      }

      return dbWallet.privateKey;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  // permanently deletes a wallet
  Future<void> deleteWallet(String address, String alias) async {
    try {
      await _encPrefs.deleteWalletBackup(address, alias);

      loadDBWallets();

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.createWalletError();
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      transferEventUnsubscribe();

      final maxDate = DateTime.now().toUtc();

      const limit = 10;

      final List<CWTransaction> txs =
          (await _db.transactions.getPreviousTransactions(
        maxDate,
        _wallet.erc20Address,
        0, // TODO: remove tokenId hardcode
        _wallet.account.hexEip55,
        offset: 0,
        limit: limit,
      ))
              .map((dbtx) => CWTransaction(
                    fromDoubleUnit(
                      dbtx.value.toString(),
                      decimals: _wallet.currency.decimals,
                    ),
                    id: dbtx.hash,
                    hash: dbtx.txHash,
                    chainId: _wallet.chainId,
                    from: EthereumAddress.fromHex(dbtx.from).hexEip55,
                    to: EthereumAddress.fromHex(dbtx.to).hexEip55,
                    title: '',
                    date: dbtx.createdAt,
                    state: TransactionState.values.firstWhereOrNull(
                          (v) => v.name == dbtx.status,
                        ) ??
                        TransactionState.success,
                  ))
              .toList();

      if (txs.isEmpty || txs.length < limit) {
        // nothing in the db or slightly less than there could be, check remote
        final (remoteTxs, _) = await _wallet.fetchErc20Transfers(
          offset: 0,
          limit: limit,
          maxDate: maxDate,
        );

        if (remoteTxs.isNotEmpty) {
          final iterableRemoteTxs = remoteTxs.map(
            (tx) => DBTransaction(
              hash: tx.hash,
              txHash: tx.txhash,
              tokenId: tx.tokenId,
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: 0, // TODO: remove nonce hardcode
              value: tx.value.toInt(),
              data: '',
              status: tx.status,
              contract: _wallet.erc20Address,
            ),
          );

          await _db.transactions.insertAll(
            iterableRemoteTxs.toList(),
          );

          txs.clear();
          txs.addAll(iterableRemoteTxs.map((dbtx) => CWTransaction(
                fromDoubleUnit(
                  dbtx.value.toString(),
                  decimals: _wallet.currency.decimals,
                ),
                id: dbtx.hash,
                hash: dbtx.txHash,
                chainId: _wallet.chainId,
                from: EthereumAddress.fromHex(dbtx.from).hexEip55,
                to: EthereumAddress.fromHex(dbtx.to).hexEip55,
                title: '',
                date: dbtx.createdAt,
                state: TransactionState.values.firstWhereOrNull(
                      (v) => v.name == dbtx.status,
                    ) ??
                    TransactionState.success,
              )));
        }
      }

      _state.loadTransactionsSuccess(
        txs.toList(),
        offset: 0,
        hasMore: txs.length >= limit,
        maxDate: maxDate,
      );

      final balance = await _wallet.balance;

      transferEventSubscribe();

      _state.updateWalletBalanceSuccess(balance);
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadTransactionsError();
  }

  Future<void> loadAdditionalTransactions(int limit) async {
    try {
      _state.loadAdditionalTransactions();

      final maxDate = _state.transactionsMaxDate;
      final offset = _state.transactionsOffset + limit;

      final List<CWTransaction> txs =
          (await _db.transactions.getPreviousTransactions(
        maxDate,
        _wallet.erc20Address,
        0, // TODO: remove tokenId hardcode
        _wallet.account.hexEip55,
        offset: offset,
        limit: limit,
      ))
              .map((dbtx) => CWTransaction(
                    fromDoubleUnit(
                      dbtx.value.toString(),
                      decimals: _wallet.currency.decimals,
                    ),
                    id: dbtx.hash,
                    hash: dbtx.txHash,
                    chainId: _wallet.chainId,
                    from: EthereumAddress.fromHex(dbtx.from).hexEip55,
                    to: EthereumAddress.fromHex(dbtx.to).hexEip55,
                    title: '',
                    date: dbtx.createdAt,
                    state: TransactionState.values.firstWhereOrNull(
                          (v) => v.name == dbtx.status,
                        ) ??
                        TransactionState.success,
                  ))
              .toList();

      if (txs.isEmpty || txs.length < limit) {
        // nothing in the db or slightly less than there could be, check remote
        final (remoteTxs, _) = await _wallet.fetchErc20Transfers(
          offset: offset,
          limit: limit,
          maxDate: maxDate,
        );

        if (remoteTxs.isNotEmpty) {
          final iterableRemoteTxs = remoteTxs.map(
            (tx) => DBTransaction(
              hash: tx.hash,
              txHash: tx.txhash,
              tokenId: tx.tokenId,
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: 0, // TODO: remove nonce hardcode
              value: tx.value.toInt(),
              data: '',
              status: tx.status,
              contract: _wallet.erc20Address,
            ),
          );

          await _db.transactions.insertAll(
            iterableRemoteTxs.toList(),
          );

          txs.clear();
          txs.addAll(iterableRemoteTxs.map((dbtx) => CWTransaction(
                fromDoubleUnit(
                  dbtx.value.toString(),
                  decimals: _wallet.currency.decimals,
                ),
                id: dbtx.hash,
                hash: dbtx.txHash,
                chainId: _wallet.chainId,
                from: EthereumAddress.fromHex(dbtx.from).hexEip55,
                to: EthereumAddress.fromHex(dbtx.to).hexEip55,
                title: '',
                date: dbtx.createdAt,
                state: TransactionState.values.firstWhereOrNull(
                      (v) => v.name == dbtx.status,
                    ) ??
                    TransactionState.success,
              )));
        }
      }

      _state.loadAdditionalTransactionsSuccess(
        txs.toList(),
        offset: offset,
        hasMore: txs.length >= limit,
      );
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadAdditionalTransactionsError();
  }

  Future<void> updateBalance() async {
    try {
      final balance = await _wallet.balance;

      final currentDoubleBalance =
          double.tryParse(_state.wallet?.balance ?? '0.0') ?? 0.0;
      final doubleBalance = double.tryParse(balance) ?? 0.0;

      if (currentDoubleBalance != doubleBalance) {
        // there was a change in balance
        HapticFeedback.lightImpact();

        _state.updateWalletBalanceSuccess(balance, notify: true);
      }
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.updateWalletBalanceError();
  }

  void removeQueuedTransaction(String id) {
    _state.sendQueueRemoveTransaction(id);
  }

  Future<bool> retryTransaction(String id) async {
    final tx = _state.attemptRetryQueuedTransaction(id);

    if (tx == null) {
      return false;
    }

    return sendTransactionFromLocked(
      tx.amount,
      tx.to,
      message: tx.title,
    );
  }

  Future<bool> sendTransaction(String amount, String to,
      {String message = '', String? id}) async {
    return kIsWeb
        ? sendTransactionFromUnlocked(amount, to, message: message, id: id)
        : sendTransactionFromLocked(amount, to, message: message, id: id);
  }

  bool isInvalidAmount(String amount) {
    final balance = double.tryParse(_state.wallet?.balance ?? '0.0') ?? 0.0;
    final doubleAmount = double.parse(toUnit(
      amount.replaceAll(',', '.'),
      decimals: _wallet.currency.decimals,
    ).toString());

    return doubleAmount == 0 || doubleAmount > balance;
  }

  bool validateSendFields(String amount, String to) {
    _state.setInvalidAddress(to.isEmpty);

    _state.setInvalidAmount(
      isInvalidAmount(amount),
    );

    return to.isNotEmpty && amount.isNotEmpty;
  }

  Future<bool> sendTransactionFromLocked(
    String amount,
    String to, {
    String message = '',
    String? id,
  }) async {
    final doubleAmount = amount.replaceAll(',', '.');
    final parsedAmount = toUnit(
      doubleAmount,
      decimals: _wallet.currency.decimals,
    );

    var tempId = id ?? '${pendingTransactionId}_${generateRandomId()}';

    try {
      _state.sendTransaction(id: id);

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      _state.preSendingTransaction(
        CWTransaction.sending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: tempId,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      final calldata = _wallet.erc20TransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      tempId = hash;

      _state.sendingTransaction(
        CWTransaction.sending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: hash,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      // this is an optional operation
      await _wallet.addSendingLog(
        TransferEvent(
          hash,
          '',
          0,
          DateTime.now().toUtc(),
          _wallet.account,
          EthereumAddress.fromHex(to),
          parsedAmount,
          Uint8List(0),
          TransactionState.sending.name,
        ),
      );

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        // this is an optional operation
        await _wallet.setStatusLog(hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      _state.pendingTransaction(
        CWTransaction.pending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: hash,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      // this is an optional operation
      await _wallet.setStatusLog(hash, TransactionState.pending);

      clearInputControllers();

      _state.sendTransactionSuccess(null);

      return true;
    } on NetworkCongestedException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkCongestedException().message),
      );
    } on NetworkInvalidBalanceException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkInvalidBalanceException().message),
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkUnknownException().message),
      );
    }

    _state.sendTransactionError();

    return false;
  }

  Future<bool> sendTransactionFromUnlocked(
    String amount,
    String to, {
    String message = '',
    String? id,
  }) async {
    final doubleAmount = amount.replaceAll(',', '.');
    final parsedAmount = toUnit(
      doubleAmount,
      decimals: _wallet.currency.decimals,
    );

    var tempId = id ?? '${pendingTransactionId}_${generateRandomId()}';

    try {
      _state.sendTransaction(id: id);

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      _state.preSendingTransaction(
        CWTransaction.sending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: tempId,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      final calldata = _wallet.erc20TransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      tempId = hash;

      _state.sendingTransaction(
        CWTransaction.sending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: hash,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      // this is an optional operation
      await _wallet.addSendingLog(
        TransferEvent(
          hash,
          '',
          0,
          DateTime.now().toUtc(),
          _wallet.account,
          EthereumAddress.fromHex(to),
          parsedAmount,
          Uint8List(0),
          TransactionState.sending.name,
        ),
      );

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        // this is an optional operation
        await _wallet.setStatusLog(hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      _state.pendingTransaction(
        CWTransaction.pending(
          fromDoubleUnit(
            parsedAmount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: hash,
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          title: message,
          date: DateTime.now(),
        ),
      );

      // this is an optional operation
      await _wallet.setStatusLog(hash, TransactionState.pending);

      clearInputControllers();

      _state.sendTransactionSuccess(null);

      return true;
    } on NetworkCongestedException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkCongestedException().message),
      );
    } on NetworkInvalidBalanceException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkInvalidBalanceException().message),
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkUnknownException().message),
      );
    }

    _state.sendTransactionError();

    return false;
  }

  void clearInputControllers() {
    _addressController.clear();
    _amountController.clear();
    _messageController.clear();
  }

  void clearAddressController() {
    _addressController.clear();
  }

  void resetInputErrorState() {
    _state.resetInvalidInputs();
  }

  void updateAddress({bool override = false}) {
    _state.setHasAddress(_addressController.text.isNotEmpty || override);
  }

  void setInvalidAddress() {
    _state.setInvalidAddress(true);
  }

  void updateAmount() {
    _state.setHasAmount(
      _amountController.text.isNotEmpty,
      isInvalidAmount(_amountController.value.text),
    );
  }

  void setMaxAmount() {
    _amountController.text = fromDoubleUnit(
      _state.wallet?.balance ?? '0.0',
      decimals: _wallet.currency.decimals,
    );
    updateAmount();
  }

  void updateAddressFromHexCapture(String raw) async {
    try {
      _state.parseQRAddress();

      _addressController.text = raw;
      _state.setHasAddress(raw.isNotEmpty);

      _state.parseQRAddressSuccess();
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _addressController.text = '';
    _state.parseQRAddressError();
  }

  Future<String?> updateFromCapture(String raw) async {
    try {
      //
      if (raw.isEmpty) {
        throw QREmptyException();
      }

      final isHex = isHexValue(raw);

      if (isHex) {
        updateAddressFromHexCapture(raw);
        return raw;
      }

      final includesHex = includesHexValue(raw);
      if (includesHex && !raw.contains('/#/')) {
        final hex = extractHexFromText(raw);
        if (hex.isNotEmpty) {
          updateAddressFromHexCapture(hex);
          return hex;
        }
      }

      final receiveUrl = Uri.parse(raw.split('/#/').last);

      final encodedParams = receiveUrl.queryParameters['receiveParams'];
      if (encodedParams == null) {
        throw QRInvalidException();
      }

      final decodedParams = decompress(encodedParams);

      final paramUrl = Uri.parse(decodedParams);

      final config = await _config.config;

      final alias = paramUrl.queryParameters['alias'];
      if (config.community.alias != alias) {
        throw QRAliasMismatchException();
      }

      final address = paramUrl.queryParameters['address'];
      if (address == null) {
        throw QRMissingAddressException();
      }

      updateAddressFromHexCapture(address);

      final amount = paramUrl.queryParameters['amount'];

      if (amount != null) {
        _amountController.text = amount;
        updateAmount();
      }

      final message = paramUrl.queryParameters['message'];

      if (message != null) {
        _messageController.text = message;
      }

      return address;
    } on QREmptyException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRInvalidException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRAliasMismatchException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRMissingAddressException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } catch (exception, stackTrace) {
      //
    }

    return null;
  }

  void updateReceiveQR({bool? onlyHex}) async {
    try {
      final config = await _config.config;

      final url = '${config.community.walletUrl(appLinkSuffix)}/#/';

      if (onlyHex != null && onlyHex) {
        final compressedParams = compress(
            '?address=${_wallet.account.hexEip55}&alias=${config.community.alias}');

        _state.updateReceiveQR('$url?receiveParams=$compressedParams');
        return;
      }

      final double amount = _amountController.value.text.isEmpty
          ? 0
          : double.tryParse(
                  _amountController.value.text.replaceAll(',', '.')) ??
              0;

      String params =
          '?address=${_wallet.account.hexEip55}&alias=${config.community.alias}';

      params += '&amount=${amount.toStringAsFixed(2)}';
      params += '&message=${_messageController.value.text}';

      final compressedParams = compress(params);

      _state.updateReceiveQR('$url?receiveParams=$compressedParams');
      return;
    } on NotFoundException {
      // HANDLE
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.clearReceiveQR();
  }

  void copyReceiveQRToClipboard(String qr) {
    Clipboard.setData(ClipboardData(text: qr));
  }

  void updateWalletQR() async {
    try {
      _state.updateWalletQR(_wallet.account.hexEip55);
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.clearWalletQR();
  }

  void copyWalletQRToClipboard() {
    Clipboard.setData(ClipboardData(text: _state.walletQR));
  }

  void copyWalletAccount() {
    try {
      Clipboard.setData(ClipboardData(text: _wallet.account.hexEip55));
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

// TODO: remove this
  Future<String?> tryUnlockWallet(String strwallet, String address) async {
    try {
      // final password =
      //     await EncryptedPreferencesService().getWalletPassword(address);

      // if (password == null) {
      //   return null;
      // }

      // // attempt to unlock the wallet
      // Wallet.fromJson(strwallet, password);

      return '';
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<CancelableOperation<void>?> loadDBWallets() async {
    try {
      _state.loadWallets();

      final wallets = await _encPrefs.getAllWalletBackups();

      _state.loadWalletsSuccess(wallets
          .map((w) => CWWallet(
                '0.0',
                name: w.name,
                address: w.address,
                alias: w.alias,
                account: '',
                currencyName: '',
                symbol: '',
                currencyLogo: '',
                locked: false,
              ))
          .toList());

      return CancelableOperation.fromFuture(
        loadDBWalletAccountAddresses(wallets.map((w) => w.address)),
        onCancel: () => cancelLoadAccounts = true,
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadWalletsError();
    return null;
  }

  Future<void> loadDBWalletAccountAddresses(Iterable<String> addrs) async {
    cancelLoadAccounts = false;
    try {
      for (final addr in addrs) {
        if (cancelLoadAccounts) {
          cancelLoadAccounts = false;
          break;
        }

        final address = EthereumAddress.fromHex(addr);

        final account = await _wallet.getAccountAddress(address.hexEip55);

        _state.updateDBWalletAccountAddress(address.hexEip55, account.hexEip55);
      }

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  void prepareReplyTransaction(String address) {
    try {
      _addressController.text = address;
      _state.setHasAddress(address.isNotEmpty);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  void prepareEditQueuedTransaction(String id) {
    final tx = _state.getQueuedTransaction(id);

    if (tx == null) {
      return;
    }

    prepareReplayTransaction(tx.to, amount: tx.amount, message: tx.title);
  }

  void prepareReplayTransaction(
    String address, {
    String amount = '0.0',
    String message = '',
  }) {
    try {
      _addressController.text = address;

      _amountController.text = double.parse('${toUnit(
        amount,
        decimals: _wallet.currency.decimals,
      )}')
          .toStringAsFixed(2);

      _messageController.text = message;

      _state.resetTransactionSendProperties();
      _state.resetInvalidInputs(notify: true);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  void pauseFetching() {
    transferEventUnsubscribe();
  }

  void resumeFetching() {
    transferEventSubscribe();
  }

  void cleanupWalletService() {
    try {
      _wallet.dispose();
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
    transferEventUnsubscribe();
  }

  void cleanupWalletState() {
    _state.cleanup();
  }

  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _messageController.dispose();

    cleanupWalletService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        transferEventSubscribe();
        break;
      default:
        transferEventUnsubscribe();
    }
  }
}
