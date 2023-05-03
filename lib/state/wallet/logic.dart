import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/transaction_request.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/models/signer.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class WalletLogic {
  late WalletState _state;
  WalletService? _wallet;
  final DBService _db = DBService();
  final PreferencesService _preferences = PreferencesService();

  StreamSubscription<String>? _blockSubscription;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TextEditingController get addressController => _addressController;
  TextEditingController get amountController => _amountController;
  TextEditingController get messageController => _messageController;

  WalletLogic(BuildContext context) {
    _state = context.read<WalletState>();
  }

  WalletService walletServiceCheck() {
    if (_wallet == null) {
      throw Exception('Wallet service not initialized');
    }

    return _wallet!;
  }

  EthPrivateKey? get privateKey {
    return walletServiceCheck().privateKey;
  }

  Future<void> switchChain(int chainId) async {
    try {
      _state.switchChainRequest();

      final walletService = walletServiceCheck();

      final chain = await walletService.fetchChainById(BigInt.from(chainId));

      if (chain == null) {
        throw Exception('Chain not found');
      }

      final dbwallet = await _db.wallet.getWallet(walletService.address.hex);

      await walletService.switchChain(chain);

      final balance = await walletService.balance;
      final currency = walletService.nativeCurrency;

      _state.switchChainSuccess(
        CWWallet(
          balance,
          name: currency.name,
          address: walletService.address.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: dbwallet.locked,
        ),
      );

      await _preferences.setChainId(chainId);

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.switchChainError();
  }

  Future<void> instantiateWalletFromDB(String address) async {
    try {
      _state.instantiateWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _db.wallet.getWallet(address);

      final wallet = await walletServiceFromChain(
        BigInt.from(chainId),
        address,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      final walletService = walletServiceCheck();

      await walletService.init();

      _state.instantiateWalletSuccess();

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.instantiateWalletError();
  }

  Future<void> instantiateWalletFromFile(
      QRWallet qrWallet, String password) async {
    try {
      _state.instantiateWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final wallet = await walletServiceFromWallet(
        BigInt.from(chainId),
        jsonEncode(qrWallet.data.wallet),
        password,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      final walletService = walletServiceCheck();

      await walletService.init();

      _state.instantiateWalletSuccess();

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.instantiateWalletError();
  }

  Future<void> openWalletFromDB(String address) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _db.wallet.getWallet(address);

      final wallet = await walletServiceFromChain(
        BigInt.from(chainId),
        address,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      final walletService = walletServiceCheck();

      await walletService.init();

      final balance = await walletService.balance;
      final currency = walletService.nativeCurrency;

      await cleanupBlockSubscription();

      _blockSubscription = walletService.blockStream.listen(onBlockHash);

      await _preferences.setLastWallet(address);

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: dbWallet.name,
          address: walletService.address.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: dbWallet.locked,
        ),
      );

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
  }

  Future<bool> openWalletFromQR(QRWallet qrWallet, String password) async {
    try {
      _state.loadWallet();

      if (kIsWeb) {
        await delay(const Duration(milliseconds: 250));
      }

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final wallet = await walletServiceFromWallet(
        BigInt.from(chainId),
        jsonEncode(qrWallet.data.wallet),
        password,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      final walletService = walletServiceCheck();

      await walletService.init();

      final balance = await walletService.balance;
      final currency = walletService.nativeCurrency;

      await cleanupBlockSubscription();

      _blockSubscription = walletService.blockStream.listen(onBlockHash);

      await _preferences.setLastWallet(wallet.address.hex);

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: 'Burner Wallet',
          address: walletService.address.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: false,
        ),
      );

      return true;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
    return false;
  }

  String? get lastWallet => _preferences.lastWallet;

  Future<String?> openWallet(String? paramAddress) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final String? address = paramAddress ?? _preferences.lastWallet;

      if (address == null) {
        throw Exception('address not found');
      }

      final dbWallet = await _db.wallet.getWallet(address);

      final wallet = await walletServiceFromChain(
        BigInt.from(chainId),
        address,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      final walletService = walletServiceCheck();

      await walletService.init();

      final balance = await walletService.balance;
      final currency = walletService.nativeCurrency;

      print('cleaning up...');
      await cleanupBlockSubscription();

      print('listening...');
      _blockSubscription = walletService.blockStream.listen(onBlockHash);

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: dbWallet.name,
          address: walletService.address.hex,
          currencyName: currency.name,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
          locked: dbWallet.locked,
        ),
      );

      _preferences.setLastWallet(address);

      return address;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
    return null;
  }

  Future<String?> createWallet(String name) async {
    try {
      _state.createDBWallet();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final password = getRandomString(64);

      final address = credentials.address.hex.toLowerCase();

      await EncryptedPreferencesService().setWalletPassword(address, password);

      final Wallet wallet =
          Wallet.createNew(credentials, password, Random.secure());

      final DBWallet dbwallet = DBWallet(
        type: 'regular',
        name: name,
        address: address,
        publicKey: wallet.privateKey.encodedPublicKey,
        balance: 0,
        wallet: wallet.toJson(),
        locked: false,
      );

      await _db.wallet.create(dbwallet);

      await _preferences.setLastWallet(address);

      _state.createDBWalletSuccess(
        dbwallet,
      );

      return credentials.address.hex;
    } catch (e) {
      print(e);
    }

    _state.createDBWalletError();

    return null;
  }

  Future<QRWallet?> importWallet(String qrWallet, String name) async {
    try {
      _state.createDBWallet();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (isPrivateKey) {
        final credentials = stringToPrivateKey(qrWallet);
        if (credentials == null) {
          throw Exception('Invalid private key');
        }

        final password = getRandomString(64);

        final address = credentials.address.hex.toLowerCase();

        await EncryptedPreferencesService()
            .setWalletPassword(address, password);

        final wallet = Wallet.createNew(credentials, password, Random.secure());

        final DBWallet dbwallet = DBWallet(
          type: 'regular',
          name: name,
          address: address,
          publicKey: wallet.privateKey.encodedPublicKey,
          balance: 0,
          wallet: wallet.toJson(),
          locked: false,
        );

        await _db.wallet.create(dbwallet);

        await _preferences.setLastWallet(address);

        _state.createDBWalletSuccess(dbwallet);

        return QRWallet(
            raw: QRWalletData(
          wallet: jsonDecode(wallet.toJson()),
          address: address,
          publicKey: wallet.privateKey.encodedPublicKey,
        ).toJson());
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = wallet.data.address.toLowerCase();

      final DBWallet dbwallet = DBWallet(
        type: 'regular',
        name: name,
        address: address,
        publicKey: wallet.data.publicKey,
        balance: 0,
        wallet: jsonEncode(wallet.data.wallet),
        locked: true,
      );

      await _db.wallet.create(dbwallet);

      await _preferences.setLastWallet(address);

      _state.createDBWalletSuccess(dbwallet);

      return wallet;
    } catch (e) {
      print(e);
    }

    _state.createDBWalletError();

    return null;
  }

  Future<void> editWallet(String address, String name) async {
    try {
      await _db.wallet.updateNameByAddress(address, name);

      loadDBWallets();

      return;
    } catch (e) {
      print(e);
    }

    _state.createDBWalletError();
  }

  void onBlockHash(String hash) async {
    try {
      _state.incomingTransactionsRequest();

      final walletService = walletServiceCheck();

      final transactions = await walletService.transactionsForBlockHash(hash);

      final cwtransactions = transactions.map((e) => CWTransaction(
            fromGwei(e.value.getValueInUnit(EtherUnit.gwei)),
            id: e.hash,
            chainId: walletService.chainId,
            from: e.from.hex,
            to: e.to.hex,
            title: e.input?.message ?? '',
            date: e.timestamp,
            blockNumber: e.blockNumber.blockNum,
          ));

      await updateBalance();

      _state.incomingTransactionsRequestSuccess(
        cwtransactions.toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.incomingTransactionsRequestError();
  }

  // takes a user password, sets a random password for the wallet and saves it in encrypted storage
  Future<void> unlockWallet(String address, String password) async {
    try {
      _state.updateWallet();

      final dbwallet = await _db.wallet.getWallet(address);

      final Wallet wallet = Wallet.fromJson(dbwallet.wallet, password);

      final newPassword = getRandomString(64);

      final random = Random.secure();

      final Wallet newWallet =
          Wallet.createNew(wallet.privateKey, newPassword, random);

      await _db.wallet.unlock(address, newWallet.toJson());

      await EncryptedPreferencesService()
          .setWalletPassword(address, newPassword);

      _state.updateWalletSuccess();

      await loadDBWallets();
      return;
    } catch (e) {
      print(e);
    }

    _state.updateWalletError();
  }

  // takes a user password and locks a wallet
  Future<void> lockWallet(String address, String password) async {
    try {
      _state.updateWallet();

      final dbwallet = await _db.wallet.getWallet(address);

      final savedPassword =
          await EncryptedPreferencesService().getWalletPassword(address);

      if (savedPassword == null) {
        throw Exception('password not found');
      }

      final Wallet wallet = Wallet.fromJson(dbwallet.wallet, savedPassword);

      final random = Random.secure();

      final Wallet newWallet =
          Wallet.createNew(wallet.privateKey, password, random);

      await _db.wallet.lock(address, newWallet.toJson());

      _state.updateWalletSuccess();

      await loadDBWallets();
      return;
    } catch (e) {
      print(e);
    }

    _state.updateWalletError();
  }

  // takes a password and returns a locked wallet
  Future<QRWallet?> lockAndReturnWallet(String address, String password) async {
    try {
      final dbwallet = await _db.wallet.getWallet(address);

      final savedPassword =
          await EncryptedPreferencesService().getWalletPassword(address);

      if (savedPassword == null) {
        throw Exception('password not found');
      }

      final Wallet wallet = Wallet.fromJson(dbwallet.wallet, savedPassword);

      final random = Random.secure();

      final Wallet newWallet =
          Wallet.createNew(wallet.privateKey, password, random);

      final qrWallet = QRWallet(
        raw: QRWalletData(
                wallet: jsonDecode(newWallet.toJson()),
                address: address,
                publicKey: wallet.privateKey.encodedPublicKey)
            .toJson(),
      );

      final signer = Signer.fromQRWallet(
        qrWallet,
        password,
      );

      await qrWallet.generateSignature(signer);

      return qrWallet;
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      final walletService = walletServiceCheck();

      final transactions = await walletService.transactions();

      final cwtransactions = transactions.map((e) => CWTransaction(
            fromGwei(e.value.getValueInUnit(EtherUnit.gwei)),
            id: e.hash,
            chainId: walletService.chainId,
            from: e.from.hex,
            to: e.to.hex,
            title: e.input?.message ?? '',
            date: e.timestamp,
            blockNumber: e.blockNumber.blockNum,
          ));

      _state.loadTransactionsSuccess(
        cwtransactions.toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadTransactionsError();
  }

  Future<void> loadAdditionalTransactions(int offset) async {
    try {
      _state.loadAdditionalTransactions();

      final walletService = walletServiceCheck();

      final transactions = await walletService.transactions(offset: offset);

      final cwtransactions = transactions.map((e) => CWTransaction(
            fromGwei(e.value.getValueInUnit(EtherUnit.gwei)),
            id: e.hash,
            chainId: walletService.chainId,
            from: e.from.hex,
            to: e.to.hex,
            title: e.input?.message ?? '',
            date: e.timestamp,
            blockNumber: e.blockNumber.blockNum,
          ));

      _state.loadAdditionalTransactionsSuccess(
        cwtransactions.toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadAdditionalTransactionsError();
  }

  Future<void> updateBalance() async {
    try {
      _state.updateWalletBalance();

      final walletService = walletServiceCheck();

      final balance = await walletService.balance;

      _state.updateWalletBalanceSuccess(balance);
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.updateWalletBalanceError();
  }

  Future<bool> sendTransaction(String amount, String to,
      {String message = ''}) async {
    return kIsWeb
        ? sendTransactionFromUnlocked(amount, to, message: message)
        : sendTransactionFromLocked(amount, to, message: message);
  }

  Future<bool> sendTransactionFromLocked(String amount, String to,
      {String message = ''}) async {
    try {
      _state.sendTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      final doubleAmount = amount.replaceAll(',', '.');

      final walletService = walletServiceCheck();

      final dbwallet = await _db.wallet.getWallet(walletService.address.hex);

      final savedPassword = await EncryptedPreferencesService()
          .getWalletPassword(walletService.address.hex);

      if (savedPassword == null) {
        throw Exception('password not found');
      }

      final hash = await walletService.sendTransaction(
        to: to,
        amount: doubleAmount,
        message: message,
        walletFile: dbwallet.wallet,
        password: savedPassword,
      );

      final transaction = CWTransaction.pending(
        doubleAmount,
        id: hash,
        title: message,
        date: DateTime.now(),
      );

      _state.sendTransactionSuccess(transaction);

      clearInputControllers();

      await updateBalance();

      return true;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.sendTransactionError();

    return false;
  }

  Future<bool> sendTransactionFromUnlocked(String amount, String to,
      {String message = ''}) async {
    try {
      _state.sendTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      final doubleAmount = amount.replaceAll(',', '.');

      final walletService = walletServiceCheck();

      final hash = await walletService.sendTransaction(
        to: to,
        amount: doubleAmount,
        message: message,
      );

      final transaction = CWTransaction.pending(
        doubleAmount,
        id: hash,
        title: message,
        date: DateTime.now(),
      );

      _state.sendTransactionSuccess(transaction);

      clearInputControllers();

      await updateBalance();

      return true;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.sendTransactionError();

    return false;
  }

  void clearInputControllers() {
    _addressController.clear();
    _amountController.clear();
    _messageController.clear();
  }

  void updateAddress() {
    _state.setHasAddress(_addressController.text.isNotEmpty);
  }

  void updateAddressFromHexCapture(String raw) async {
    try {
      _state.parseQRAddress();

      _addressController.text = raw;
      _state.setHasAddress(raw.isNotEmpty);

      _state.parseQRAddressSuccess();
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _addressController.text = '';
    _state.parseQRAddressError();
  }

  void updateAddressFromWalletCapture(String raw) async {
    try {
      _state.parseQRAddress();

      final qr = QR.fromCompressedJson(raw);

      final qrWallet = qr.toQRWallet();

      final verified = await qrWallet.verifyData();
      // TODO: implement a visual warning that the code is not signed
      // if (!verified) {
      //   throw signatureException;
      // }

      _addressController.text = qrWallet.data.address;
      _state.setHasAddress(qrWallet.data.address.isNotEmpty);

      _state.parseQRAddressSuccess();
      return;
    } catch (e) {
      print('error');
      print(e);
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
    } catch (e) {
      print(e);
    }
  }

  void updateTransactionFromTransactionCapture(String raw) async {
    try {
      final qr = QR.fromCompressedJson(raw);

      final qrTransaction = qr.toQRTransactionRequest();

      final verified = await qrTransaction.verifyData();
      // TODO: implement a visual warning that the code is not signed
      // if (!verified) {
      //   throw signatureException;
      // }

      _addressController.text = qrTransaction.data.address;
      _state.setHasAddress(qrTransaction.data.address.isNotEmpty);
      _state.parseQRAddressSuccess();

      if (qrTransaction.data.amount >= 0) {
        final walletService = walletServiceCheck();

        _amountController.text = qrTransaction.data.amount
            .toStringAsFixed(walletService.nativeCurrency.decimals);
      }

      if (qrTransaction.data.message != '') {
        _messageController.text = qrTransaction.data.message;
      }

      return;
    } catch (e) {
      print(e);
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
      final walletService = walletServiceCheck();

      if (onlyHex != null && onlyHex) {
        _state.updateReceiveQR(walletService.address.hex);
        return;
      }

      final double amount = _amountController.value.text.isEmpty
          ? 0
          : double.tryParse(
                  _amountController.value.text.replaceAll(',', '.')) ??
              0;

      final dbwallet = await _db.wallet.getWallet(walletService.address.hex);

      final qrData = QRTransactionRequestData(
        chainId: walletService.chainId,
        address: dbwallet.address,
        amount: amount,
        message: _messageController.value.text,
        publicKey: dbwallet.publicKey,
      );

      final qr = QRTransactionRequest(raw: qrData.toJson());

      final savedPassword = await EncryptedPreferencesService()
          .getWalletPassword(dbwallet.address);

      if (savedPassword != null) {
        final credentials = walletService.unlock(
            walletFile: dbwallet.wallet, password: savedPassword);

        if (credentials != null) {
          final signer = Signer(credentials);

          await qr.generateSignature(signer);
        }
      }

      final compressed = qr.toCompressedJson();

      _state.updateReceiveQR(compressed);
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.clearReceiveQR();
  }

  void updateReceiveQRUnlocked({bool? onlyHex}) async {
    try {
      final walletService = walletServiceCheck();

      if (onlyHex != null && onlyHex) {
        _state.updateReceiveQR(walletService.address.hex);
        return;
      }

      final double amount = _amountController.value.text.isEmpty
          ? 0
          : double.tryParse(
                  _amountController.value.text.replaceAll(',', '.')) ??
              0;

      final credentials = walletService.unlock();

      if (credentials == null) {
        throw 'Could not retrieve credentials from wallet';
      }

      final qrData = QRTransactionRequestData(
        chainId: walletService.chainId,
        address: credentials.address.hex,
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
    } catch (e) {
      print('error');
      print(e);
    }

    _state.clearReceiveQR();
  }

  void copyReceiveQRToClipboard() {
    Clipboard.setData(ClipboardData(text: _state.receiveQR));
  }

  void updateWalletQR({bool? onlyHex}) async {
    try {
      final walletService = walletServiceCheck();

      if (onlyHex != null && onlyHex) {
        _state.updateWalletQR(walletService.address.hex);
        return;
      }

      final dbwallet = await _db.wallet.getWallet(walletService.address.hex);

      final qrData = QRWalletData(
        wallet: jsonDecode(dbwallet.wallet),
        address: dbwallet.address,
        publicKey: dbwallet.publicKey,
      );

      final qr = QRWallet(raw: qrData.toJson());

      final savedPassword = await EncryptedPreferencesService()
          .getWalletPassword(dbwallet.address);

      if (savedPassword != null) {
        final credentials = walletService.unlock(
            walletFile: dbwallet.wallet, password: savedPassword);

        if (credentials != null) {
          final signer = Signer(credentials);

          await qr.generateSignature(signer);
        }
      }

      final compressed = qr.toCompressedJson();

      _state.updateWalletQR(compressed);
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.clearWalletQR();
  }

  void copyWalletQRToClipboard() {
    Clipboard.setData(ClipboardData(text: _state.walletQR));
  }

  Future<String?> tryUnlockWallet(String strwallet, String address) async {
    try {
      final password =
          await EncryptedPreferencesService().getWalletPassword(address);

      if (password == null) {
        return null;
      }

      // attempt to unlock the wallet
      Wallet.fromJson(strwallet, password);

      return password;
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<bool> verifyWalletPassword(String strwallet, String password) async {
    try {
      final Wallet wallet = Wallet.fromJson(strwallet, password);

      final random = Random.secure();

      final newPassword = getRandomString(64);

      final Wallet newWallet =
          Wallet.createNew(wallet.privateKey, newPassword, random);

      await _db.wallet.updateRawWallet(
        newWallet.privateKey.address.hex,
        newWallet.toJson(),
      );

      await EncryptedPreferencesService()
          .setWalletPassword(newWallet.privateKey.address.hex, newPassword);

      _state.setInvalidPassword(false);

      return true;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.setInvalidPassword(true);

    return false;
  }

  Future<String?> fetchDBWallet(String address) async {
    try {
      final dbWallet = await _db.wallet.getWallet(address);

      return dbWallet.wallet;
    } catch (e) {
      print('error');
      print(e);
    }

    return null;
  }

  Future<void> loadDBWallets() async {
    try {
      _state.loadDBWallets();

      final wallets = await _db.wallet.getRegularWallets();

      _state.loadDBWalletsSuccess(wallets);
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadDBWalletsError();
  }

  void prepareReplyTransaction(String address) {
    try {
      _addressController.text = address;
      _state.setHasAddress(address.isNotEmpty);
    } catch (e) {
      print(e);
    }
  }

  void prepareReplayTransaction(
    String address, {
    String amount = '0.0',
    String message = '',
  }) {
    try {
      _addressController.text = address;
      _state.setHasAddress(address.isNotEmpty);

      _amountController.text = amount;

      _messageController.text = message;
    } catch (e) {
      print(e);
    }
  }

  Future<void> cleanupBlockSubscription() async {
    if (_blockSubscription != null) {
      await _blockSubscription!.cancel();
    }
  }

  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    try {
      final walletService = walletServiceCheck();
      walletService.dispose();
    } catch (e) {
      print(e);
    }
    cleanupBlockSubscription();
  }
}
