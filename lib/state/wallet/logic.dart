import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/transaction_request.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet2.dart';
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

class WalletLogic extends WidgetsBindingObserver {
  late WalletState _state;

  final WalletService2 _wallet = WalletService2();

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

  Future<bool> openWalletFromURL(
    String encodedWallet,
    String password,
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

      await _wallet.init(
        bytesToHex(cred.privateKey.privateKey),
        NativeCurrency(
          name: 'USD Coin',
          symbol: 'USDC',
          decimals: 2,
        ),
        dotenv.get('ERC4337_ENTRYPOINT'),
        dotenv.get('ERC4337_ACCOUNT_FACTORY'),
        dotenv.get('ERC20_TOKEN_ADDRESS'),
        dotenv.get('PROFILE_ADDRESS'),
      );

      final balance = await _wallet.balance;
      final currency = _wallet.currency;

      _state.setWallet(
        CWWallet(
          balance,
          name:
              'Citizen Wallet', // on web, acts as a page's title, wallet is fitting here
          address: _wallet.address.hex,
          account: _wallet.account.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: false,
        ),
      );

      await loadAdditionalData();

      await _preferences.setLastWallet(_wallet.address.hex);
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

  String? get lastWallet => _preferences.lastWallet;

  Future<String?> openWallet(
      String? paramAddress, Future<void> Function() loadAdditionalData) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final String? address = paramAddress ?? _preferences.lastWallet;

      if (address == null) {
        throw Exception('address not found');
      }

      final dbWallet = await _encPrefs.getWalletBackup(address);

      if (dbWallet == null || dbWallet.privateKey.isEmpty) {
        throw NotFoundException();
      }

      await _wallet.init(
        dbWallet.privateKey,
        NativeCurrency(
          name: 'USD Coin',
          symbol: 'USDC',
          decimals: 2,
        ),
        dotenv.get('ERC4337_ENTRYPOINT'),
        dotenv.get('ERC4337_ACCOUNT_FACTORY'),
        dotenv.get('ERC20_TOKEN_ADDRESS'),
        dotenv.get('PROFILE_ADDRESS'),
      );

      final balance = await _wallet.balance;
      final currency = _wallet.currency;

      _state.setWallet(
        CWWallet(
          balance,
          name: dbWallet.name,
          address: _wallet.address.hex,
          account: _wallet.account.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: dbWallet.privateKey.isEmpty,
        ),
      );

      await loadAdditionalData();

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

  Future<String?> createWallet(String name) async {
    try {
      _state.createWallet();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final address = credentials.address.hex.toLowerCase();

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: address,
        account: '',
        currencyName: '',
        symbol: '',
        locked: false,
      );

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: bytesToHex(credentials.privateKey),
        name: name,
      ));

      await _preferences.setLastWallet(address);

      _state.createWalletSuccess(
        cwwallet,
      );

      return credentials.address.hex;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.createWalletError();

    return null;
  }

  Future<String?> importWallet(String qrWallet, String name) async {
    try {
      _state.createWallet();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (isPrivateKey) {
        final credentials = stringToPrivateKey(qrWallet);
        if (credentials == null) {
          throw Exception('Invalid private key');
        }

        final address = credentials.address.hex.toLowerCase();

        final CWWallet cwwallet = CWWallet(
          '0.0',
          name: name,
          address: address,
          account: '',
          currencyName: '',
          symbol: '',
          locked: false,
        );

        await _encPrefs.setWalletBackup(BackupWallet(
          address: address,
          privateKey: bytesToHex(credentials.privateKey),
          name: name,
        ));

        await _preferences.setLastWallet(address);

        _state.createWalletSuccess(cwwallet);

        return address;
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = wallet.data.address.toLowerCase();

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: address,
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

      if (txs.isEmpty) {
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
          from: tx.from.hex,
          to: tx.to.hex,
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
            from: tx.from.hex,
            to: tx.to.hex,
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
          from: tx.from.hex,
          to: tx.to.hex,
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

      HapticFeedback.lightImpact();

      _state.updateWalletBalanceSuccess(balance, notify: true);

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

      final tx = await _wallet.addSendingLog(
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
      if (tx == null) {
        throw Exception('failed to send log');
      }

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        await _wallet.setStatusLog(tx.hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      await _wallet.setStatusLog(tx.hash, TransactionState.pending);

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

      final tx = await _wallet.addSendingLog(
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
      if (tx == null) {
        throw Exception('failed to send log');
      }

      final success = await _wallet.submitUserop(userop);
      if (!success) {
        await _wallet.setStatusLog(tx.hash, TransactionState.fail);
        throw Exception('transaction failed');
      }

      await _wallet.setStatusLog(tx.hash, TransactionState.pending);

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

  void resetInputErrorState() {
    _state.resetInvalidInputs();
  }

  void updateAddress() {
    _state.setHasAddress(_addressController.text.isNotEmpty);
  }

  void updateAmount() {
    _state.setHasAmount(
      _amountController.text.isNotEmpty,
      isInvalidAmount(_amountController.value.text),
    );
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

  void updateAddressFromWalletCapture(String raw) async {
    try {
      _state.parseQRAddress();

      final qr = QR.fromCompressedJson(raw);

      final qrWallet = qr.toQRWallet();

      // final verified = await qrWallet.verifyData();
      // TODO: implement a visual warning that the code is not signed
      // if (!verified) {
      //   throw signatureException;
      // }

      _addressController.text = qrWallet.data.address;
      _state.setHasAddress(qrWallet.data.address.isNotEmpty);

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

  void updateFromCapture(String raw) {
    try {
      final isHex = isHexValue(raw);

      if (isHex) {
        updateAddressFromHexCapture(raw);
        return;
      }

      final includesHex = includesHexValue(raw);
      if (includesHex) {
        final hex = extractHexFromText(raw);
        if (hex.isNotEmpty) {
          updateAddressFromHexCapture(hex);
          return;
        }
      }

      final qr = QR.fromCompressedJson(raw);

      switch (qr.type) {
        case QRType.qrWallet:
          updateAddressFromWalletCapture(raw);
          break;
        case QRType.qrTransactionRequest:
          updateTransactionFromTransactionCapture(raw);
          break;
        default:
      }
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  void updateTransactionFromTransactionCapture(String raw) async {
    try {
      final qr = QR.fromCompressedJson(raw);

      final qrTransaction = qr.toQRTransactionRequest();

      // final verified = await qrTransaction.verifyData();
      // TODO: implement a visual warning that the code is not signed
      // if (!verified) {
      //   throw signatureException;
      // }

      _addressController.text = qrTransaction.data.address;
      _state.setHasAddress(qrTransaction.data.address.isNotEmpty);
      _state.parseQRAddressSuccess();

      if (qrTransaction.data.amount >= 0) {
        _amountController.text = qrTransaction.data.amount
            .toStringAsFixed(_wallet.currency.decimals);
      }

      if (qrTransaction.data.message != '') {
        _messageController.text = qrTransaction.data.message;
      }

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.parseQRAddressError();
  }

  void updateReceiveQR({bool? onlyHex}) async {
    return kIsWeb
        ? updateReceiveQRUnlocked(onlyHex: onlyHex)
        : updateReceiveQRLocked(onlyHex: onlyHex);
  }

  void updateReceiveQRLocked({bool? onlyHex}) async {
    try {
      if (onlyHex != null && onlyHex) {
        _state.updateReceiveQR(_wallet.account.hex);
        return;
      }

      final double amount = _amountController.value.text.isEmpty
          ? 0
          : double.tryParse(
                  _amountController.value.text.replaceAll(',', '.')) ??
              0;

      final dbWallet = await _encPrefs.getWalletBackup(_wallet.address.hex);

      if (dbWallet == null) {
        throw NotFoundException();
      }

      final credentials = EthPrivateKey.fromHex(dbWallet.privateKey);

      final qrData = QRTransactionRequestData(
        chainId: _wallet.chainId,
        address: _wallet.account.hex,
        amount: amount,
        message: _messageController.value.text,
        publicKey: credentials.encodedPublicKey,
      );

      final qr = QRTransactionRequest(raw: qrData.toJson());

      final signer = Signer(credentials);

      await qr.generateSignature(signer);

      final compressed = qr.toCompressedJson();

      _state.updateReceiveQR(compressed);
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

  void updateReceiveQRUnlocked({bool? onlyHex}) async {
    try {
      if (onlyHex != null && onlyHex) {
        _state.updateReceiveQR(_wallet.account.hex);
        return;
      }

      final double amount = _amountController.value.text.isEmpty
          ? 0
          : double.tryParse(
                  _amountController.value.text.replaceAll(',', '.')) ??
              0;

      final qrData = QRTransactionRequestData(
        chainId: _wallet.chainId,
        address: _wallet.account.hex,
        amount: amount,
        message: _messageController.value.text,
        publicKey: _wallet.credentials.encodedPublicKey,
      );

      final qr = QRTransactionRequest(raw: qrData.toJson());

      final signer = Signer(_wallet.credentials);

      await qr.generateSignature(signer);

      final compressed = qr.toCompressedJson();

      _state.updateReceiveQR(compressed);
      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.clearReceiveQR();
  }

  void copyReceiveQRToClipboard() {
    Clipboard.setData(ClipboardData(text: _state.receiveQR));
  }

  void updateWalletQR() async {
    try {
      _state.updateWalletQR(_wallet.account.hex);
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
      Clipboard.setData(ClipboardData(text: _wallet.account.hex));
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

        _state.updateDBWalletAccountAddress(addr, account.hex);

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
