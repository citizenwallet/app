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
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class WalletLogic {
  late WalletState _state;
  late WalletService _wallet;
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

  Future<void> switchChain(int chainId) async {
    try {
      _state.switchChainRequest();

      final chain = await _wallet.fetchChainById(BigInt.from(chainId));

      if (chain == null) {
        throw Exception('Chain not found');
      }

      await _wallet.switchChain(chain);

      final balance = await _wallet.balance;
      final currency = _wallet.nativeCurrency;

      _state.switchChainSuccess(
        CWWallet(
          balance,
          name: currency.name,
          address: _wallet.address.hex,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
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

  Future<void> openWalletFromDB(String address) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _db.wallet.getWallet(address);

      final password =
          await EncryptedPreferencesService().getWalletPassword(address);

      if (password == null) {
        throw Exception('password not found');
      }

      final wallet = await walletServiceFromChain(
        BigInt.from(chainId),
        dbWallet.wallet,
        password,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      await _wallet.init();

      final balance = await _wallet.balance;
      final currency = _wallet.nativeCurrency;

      cleanupBlockSubscription();

      _blockSubscription = _wallet.blockStream.listen(onBlockHash);

      await _preferences.setLastWallet(address);

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: currency.name,
          address: _wallet.address.hex,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
        ),
      );

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
  }

  Future<void> openWallet(String address, String password) async {
    try {
      _state.loadWallet();

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final dbWallet = await _db.wallet.getWallet(address);

      final wallet = await walletServiceFromChain(
        BigInt.from(chainId),
        dbWallet.wallet,
        password,
      );

      if (wallet == null) {
        throw Exception('chain not found');
      }

      _wallet = wallet;

      await _wallet.init();

      final balance = await _wallet.balance;
      final currency = _wallet.nativeCurrency;

      cleanupBlockSubscription();

      _blockSubscription = _wallet.blockStream.listen(onBlockHash);

      _state.loadWalletSuccess(
        CWWallet(
          balance,
          name: currency.name,
          address: _wallet.address.hex,
          symbol: currency.symbol,
          decimalDigits: currency.decimals,
        ),
      );

      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadWalletError();
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
        id: 0,
        type: 'regular',
        name: name,
        address: address,
        balance: 0,
        wallet: wallet.toJson(),
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

  void onBlockHash(String hash) async {
    try {
      _state.incomingTransactionsRequest();

      final transactions = await _wallet.transactionsForBlockHash(hash);

      _state.incomingTransactionsRequestSuccess(
        transactions
            .map((e) => CWTransaction(
                  e.value.getInEther.toDouble(),
                  id: e.hash,
                  chainId: _wallet.chainId,
                  from: e.from.hex,
                  to: e.to.hex,
                  title: e.input?.message ?? '',
                  date: e.timestamp,
                ))
            .toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.incomingTransactionsRequestError();
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      final transactions = await _wallet.transactions();

      _state.loadTransactionsSuccess(
        transactions
            .map((e) => CWTransaction(
                  e.value.getInEther.toDouble(),
                  id: e.hash,
                  chainId: _wallet.chainId,
                  from: e.from.hex,
                  to: e.to.hex,
                  title: e.input?.message ?? '',
                  date: e.timestamp,
                ))
            .toList(),
      );
      return;
    } catch (e) {
      print('error');
      print(e);
    }

    _state.loadTransactionsError();
  }

  Future<void> updateBalance() async {
    try {
      _state.updateWalletBalance();

      final balance = await _wallet.balance;

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
    try {
      _state.sendTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      var doubleAmount = double.tryParse(amount.replaceAll(',', '.'));
      if (doubleAmount == null) {
        _state.setInvalidAmount(true);
        throw Exception('invalid amount');
      }

      final hash = await _wallet.sendTransaction(
        to: to,
        amount: doubleAmount.toInt(),
        message: message,
      );

      _state.sendTransactionSuccess(CWTransaction.pending(
        doubleAmount,
        id: hash,
        title: message,
        date: DateTime.now(),
      ));

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

  void updateAddressFromWalletCapture(String raw) async {
    try {
      _state.parseQRAddress();

      final qr = QR.fromCompressedJson(raw);

      final qrWallet = qr.toQRWallet();

      final verified = await qrWallet.verifyData();
      if (!verified) {
        throw signatureException;
      }

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
      if (!verified) {
        throw signatureException;
      }

      _addressController.text = qrTransaction.data.address;
      _state.setHasAddress(qrTransaction.data.address.isNotEmpty);
      _state.parseQRAddressSuccess();

      if (qrTransaction.data.amount >= 0) {
        _amountController.text = qrTransaction.data.amount
            .toStringAsFixed(_wallet.nativeCurrency.decimals);
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

  void updateReceiveQR() async {
    try {
      final double amount = _amountController.text.isEmpty
          ? 0
          : double.tryParse(_amountController.text) ?? 0;

      final qrData = QRTransactionRequestData(
        chainId: _wallet.chainId,
        address: _wallet.address.hex,
        amount: amount,
        publicKey: _wallet.publicKey,
      );

      final qr = QRTransactionRequest(raw: qrData.toJson());

      final signer = Signer(_wallet.privateKey);

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

  void updateWalletQR() async {
    try {
      if (_wallet.wallet == null) {
        throw Exception('wallet not set');
      }

      final raw = await _db.wallet.getWallet(_wallet.address.hex);

      final qrData = QRWalletData(
        wallet: jsonDecode(raw.wallet),
        address: _wallet.address.hex,
        publicKey: _wallet.publicKey,
      );

      final qr = QRWallet(raw: qrData.toJson());

      final signer = Signer(_wallet.privateKey);

      await qr.generateSignature(signer);

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

  void cleanupBlockSubscription() {
    if (_blockSubscription != null) {
      _blockSubscription!.cancel();
    }
  }

  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _messageController.dispose();
    _wallet.dispose();
    cleanupBlockSubscription();
  }
}
