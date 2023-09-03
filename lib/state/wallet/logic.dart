import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/cache/contacts.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/db.dart';
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

  Future<String> getCommunityNameFromConfig() async {
    try {
      // on web, use host
      _config.initWeb(
        dotenv.get('APP_LINK_SUFFIX'),
      );

      final config = await _config.config;

      String name = config.community.name;
      if (!name.toLowerCase().contains('wallet')) {
        name = '$config.token.symbol Wallet';
      }

      return name;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return 'Citizen Wallet';
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

      _state.setWallet(
        CWWallet(
          balance,
          name:
              'Citizen Wallet', // on web, acts as a page's title, wallet is fitting here
          address: _wallet.address.hexEip55,
          alias: alias == 'localhost' ? 'app' : alias,
          account: _wallet.account.hexEip55,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: false,
        ),
      );

      await loadAdditionalData();

      await _preferences.setLastWallet(_wallet.address.hexEip55);
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
    Future<void> Function(bool hasChanged) loadAdditionalData,
  ) async {
    try {
      final String? address = paramAddress ?? _preferences.lastWallet;

      if (address == null) {
        throw Exception('address not found');
      }

      if (isWalletLoaded && paramAddress == _wallet.address.hexEip55) {
        final balance = await _wallet.balance;

        _state.updateWalletBalanceSuccess(balance);

        await loadAdditionalData(false);

        _state.loadWalletSuccess();

        _preferences.setLastWallet(address);

        return address;
      }

      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _encPrefs.getWalletBackup(address);

      if (dbWallet == null || dbWallet.privateKey.isEmpty) {
        throw NotFoundException();
      }

      // on native, use env
      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        dbWallet.alias,
      );

      final config = await _config.config;

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

      _state.setWallet(
        CWWallet(
          balance,
          name: dbWallet.name,
          address: _wallet.address.hexEip55,
          alias: dbWallet.alias,
          account: _wallet.account.hexEip55,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: dbWallet.privateKey.isEmpty,
        ),
      );

      await loadAdditionalData(true);

      _state.loadWalletSuccess();

      _preferences.setLastWallet(address);

      return address;
    } on NotFoundException {
      _state.loadWalletError(exception: NotFoundException());

      Sentry.captureException(
        NotFoundException(),
      );

      return null;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.loadWalletError();
    return null;
  }

  Future<String?> createWallet(String name, String alias) async {
    try {
      _state.createWallet();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final address = credentials.address.hexEip55;

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: address,
        alias: alias == 'localhost' ? 'app' : alias,
        account: '',
        currencyName: '',
        symbol: '',
        locked: false,
      );

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: bytesToHex(credentials.privateKey),
        name: name,
        alias: alias == 'localhost' ? 'app' : alias,
      ));

      await _preferences.setLastWallet(address);

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

  Future<String?> importWallet(
      String qrWallet, String name, String alias) async {
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

        final CWWallet cwwallet = CWWallet(
          '0.0',
          name: name,
          address: address,
          alias: alias == 'localhost' ? 'app' : alias,
          account: '',
          currencyName: '',
          symbol: '',
          locked: false,
        );

        await _encPrefs.setWalletBackup(BackupWallet(
          address: address,
          privateKey: bytesToHex(credentials.privateKey),
          name: name,
          alias: alias == 'localhost' ? 'app' : alias,
        ));

        await _preferences.setLastWallet(address);

        _state.createWalletSuccess(cwwallet);

        return address;
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = EthereumAddress.fromHex(wallet.data.address).hexEip55;

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: address,
        alias: alias == 'localhost' ? 'app' : alias,
        account: '',
        currencyName: '',
        symbol: '',
        locked: false,
      );

      // TODO: fix this, not sure if we can extract the private key from the wallet json like this
      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: bytesToHex(wallet.data.wallet['privateKey']),
        name: name,
        alias: alias == 'localhost' ? 'app' : alias,
      ));

      await _preferences.setLastWallet(address);

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
      final dbWallet = await _encPrefs.getWalletBackup(address);
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

        await delay(const Duration(seconds: 2));

        fetchNewTransfers(id);
        return;
      }

      if (txs.isEmpty) {
        // successful but there's nothing

        // still keep balance up to date no matter what
        updateBalance();

        await delay(const Duration(seconds: 2));

        fetchNewTransfers(id);
        return;
      }

      final cwtransactions = txs.map(
        (tx) => CWTransaction(
          fromUnit(tx.value),
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

      final hasChanges = _state.incomingTransactionsRequestSuccess(
        cwtransactions.toList(),
      );

      if (hasChanges) {
        updateBalance();
      }

      await delay(const Duration(seconds: 2));

      fetchNewTransfers(id);
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.incomingTransactionsRequestError();
    await delay(const Duration(seconds: 2));

    fetchNewTransfers(id);
  }

  // takes a password and returns a wallet
  Future<String?> returnWallet(String address) async {
    try {
      final dbWallet = await _encPrefs.getWalletBackup(address);
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
  Future<void> deleteWallet(String address) async {
    try {
      await _encPrefs.deleteWalletBackup(address);

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

      final (txs, pagination) = await _wallet.fetchErc20Transfers(
        offset: 0,
        limit: limit,
        maxDate: maxDate,
      );

      final cwtransactions = txs.map(
        (tx) => CWTransaction(fromUnit(tx.value),
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
                TransactionState.success),
      );

      _state.loadTransactionsSuccess(
        cwtransactions.toList(),
        offset: pagination.offset,
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

      final (txs, pagination) = await _wallet.fetchErc20Transfers(
        offset: _state.transactionsOffset + limit,
        limit: limit,
        maxDate: _state.transactionsMaxDate,
      );

      final cwtransactions = txs.map(
        (tx) => CWTransaction(
          fromUnit(tx.value),
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

      _state.loadAdditionalTransactionsSuccess(
        cwtransactions.toList(),
        offset: pagination.offset,
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

    return sendTransactionFromLocked('${double.parse(tx.amount) / 1000}', tx.to,
        message: tx.title);
  }

  Future<bool> sendTransaction(String amount, String to,
      {String message = '', String? id}) async {
    return kIsWeb
        ? sendTransactionFromUnlocked(amount, to, message: message, id: id)
        : sendTransactionFromLocked(amount, to, message: message, id: id);
  }

  bool isInvalidAmount(String amount) {
    final balance = double.tryParse(_state.wallet?.balance ?? '0.0') ?? 0.0;
    final doubleAmount =
        (double.tryParse(amount.replaceAll(',', '.')) ?? 0.0) * 1000;

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
    final parsedAmount = double.parse(doubleAmount) * 1000;

    var tempId = id ?? '${pendingTransactionId}_${generateRandomId()}';

    try {
      _state.sendTransaction(id: id);

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      _state.preSendingTransaction(
        CWTransaction.sending(
          '$parsedAmount',
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
        BigInt.from(double.parse(doubleAmount) * 1000),
      );

      final (hash, userop) = await _wallet.prepareUserop(
        _wallet.erc20Address,
        calldata,
      );

      tempId = hash;

      _state.sendingTransaction(
        CWTransaction.sending(
          '$parsedAmount',
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
          EtherAmount.fromBigInt(
            EtherUnit.kwei,
            BigInt.from(double.parse(doubleAmount) * 1000),
          ).getInWei,
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
          '$parsedAmount',
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
        CWTransaction.failed('$parsedAmount',
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkCongestedException().message),
      );
    } on NetworkInvalidBalanceException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed('$parsedAmount',
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
        CWTransaction.failed('$parsedAmount',
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

  Future<bool> sendTransactionFromUnlocked(String amount, String to,
      {String message = '', String? id}) async {
    final doubleAmount = amount.replaceAll(',', '.');
    final parsedAmount = double.parse(doubleAmount) * 1000;

    var tempId = id ?? '${pendingTransactionId}_${generateRandomId()}';

    try {
      _state.sendTransaction(id: id);

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      _state.preSendingTransaction(
        CWTransaction.sending(
          '$parsedAmount',
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
        BigInt.from(double.parse(doubleAmount) * 1000),
      );

      final (hash, userop) = await _wallet.prepareUserop(
        _wallet.erc20Address,
        calldata,
      );

      tempId = hash;

      _state.sendingTransaction(
        CWTransaction.sending(
          '$parsedAmount',
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
          EtherAmount.fromBigInt(
            EtherUnit.kwei,
            BigInt.from(double.parse(doubleAmount) * 1000),
          ).getInWei,
          Uint8List(0),
          TransactionState.sending.name,
        ),
      );

      // this needs to succeeds
      final success = await _wallet.submitUserop(userop);
      if (!success) {
        // this is an optional operation
        await _wallet.setStatusLog(hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      _state.pendingTransaction(
        CWTransaction.pending(
          '$parsedAmount',
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
        CWTransaction.failed('$parsedAmount',
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkCongestedException().message),
      );
    } on NetworkInvalidBalanceException {
      _state.sendQueueAddTransaction(
        CWTransaction.failed('$parsedAmount',
            id: tempId,
            hash: '',
            to: to,
            title: message,
            date: DateTime.now(),
            error: NetworkInvalidBalanceException().message),
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
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
    _amountController.text =
        (double.parse(_state.wallet?.balance ?? '0.0') / 1000)
            .toStringAsFixed(2);
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

      final url = config.community.customDomain != ''
          ? 'https://${config.community.customDomain}/#/'
          : 'https://${config.community.alias}$appLinkSuffix/#/';

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

        final account = await _wallet.getAccountAddress(addr);

        _state.updateDBWalletAccountAddress(addr, account.hexEip55);

        await delay(const Duration(milliseconds: 250));
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

      _amountController.text = (double.parse(amount) / 1000).toStringAsFixed(2);

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
