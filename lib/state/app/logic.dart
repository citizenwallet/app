import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/encrypted_preferences/android.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class AppLogic {
  final PreferencesService _preferences = PreferencesService();
  final EncryptedPreferencesService _encPrefs =
      getEncryptedPreferencesService();
  late AppState _appState;

  AppLogic(BuildContext context) {
    _appState = context.read<AppState>();
  }

  void setDarkMode(bool darkMode) {
    _preferences.setDarkMode(darkMode);

    _appState.darkMode = darkMode;
  }

  void setFirstLaunch(bool firstLaunch) {
    _preferences.setFirstLaunch(firstLaunch);
  }

  void loadChains() async {
    try {
      _appState.loadChains();

      final List rawNativeChains = jsonDecode(
          await rootBundle.loadString('assets/data/native_chains.json'));

      final List<Chain> nativeChains =
          rawNativeChains.map((c) => Chain.fromJson(c)).toList();

      final List rawChains =
          jsonDecode(await rootBundle.loadString('assets/data/chains.json'));

      final List<Chain> chains =
          rawChains.map((c) => Chain.fromJson(c)).toList();

      final List<Chain> allChains = [...nativeChains, ...chains];

      _appState.loadChainsSuccess(allChains);

      return;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.loadChainsError();
  }

  Future<String?> loadLastWallet() async {
    try {
      _appState.importLoadingReq();
      final String? lastWallet = _preferences.lastWallet;

      BackupWallet? dbWallet;
      if (lastWallet != null) {
        dbWallet = await _encPrefs.getWalletBackup(lastWallet);
      }

      if (dbWallet == null) {
        // attempt to see if there are any other wallets backed up
        final dbWallets = await _encPrefs.getAllWalletBackups();

        if (dbWallets.isNotEmpty) {
          final dbWallet = dbWallets[0];

          final address = EthereumAddress.fromHex(dbWallet.address).hexEip55;

          await _preferences.setLastWallet(address);

          _appState.importLoadingSuccess();

          return address;
        }

        _appState.importLoadingError();

        return null;
      }

      await delay(
          const Duration(milliseconds: 1500)); // smoother launch experience

      _appState.importLoadingSuccess();

      final address = EthereumAddress.fromHex(dbWallet.address).hexEip55;

      return address;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return null;
  }

  Future<bool> isVerifiedWallet(String qrWallet) async {
    try {
      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      return wallet.verifyData();
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return false;
  }

  Future<String?> createWallet(String name) async {
    try {
      _appState.importLoadingReq();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final address = credentials.address.hexEip55;

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: (bytesToHex(credentials.privateKey)),
        name: name,
      ));

      await _preferences.setLastWallet(address);

      _appState.importLoadingSuccess();

      return credentials.address.hexEip55;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return null;
  }

  Future<String?> getLastEncodedWallet() async {
    try {
      final String? lastWallet = _preferences.lastWalletLink;

      if (lastWallet == null) {
        return null;
      }

      await delay(const Duration(milliseconds: 1500));

      return lastWallet;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    return null;
  }

  Future<String?> createWebWallet() async {
    try {
      _appState.importLoadingWebReq();

      await delay(const Duration(milliseconds: 0));

      final credentials = EthPrivateKey.createRandom(Random.secure());

      await delay(const Duration(milliseconds: 0));

      final password = dotenv.get('WEB_BURNER_PASSWORD');

      final Wallet wallet = Wallet.createNew(
        credentials,
        password,
        Random.secure(),
        scryptN:
            512, // TODO: increase factor if we can threading >> https://stackoverflow.com/questions/11126315/what-are-optimal-scrypt-work-factors
      );

      await delay(const Duration(milliseconds: 0));

      _appState.importLoadingWebSuccess(password);

      return 'v2-${base64Encode(wallet.toJson().codeUnits)}';
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingWebError();

    return null;
  }

  Future<String?> importWallet(String qrWallet, String name) async {
    try {
      _appState.importLoadingReq();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (isPrivateKey) {
        final credentials = stringToPrivateKey(qrWallet);
        if (credentials == null) {
          throw Exception('Invalid private key');
        }

        final address = credentials.address.hexEip55;

        await _encPrefs.setWalletBackup(
          BackupWallet(
            address: address,
            privateKey: bytesToHex(credentials.privateKey),
            name: name,
          ),
        );

        await _preferences.setLastWallet(address);

        _appState.importLoadingSuccess();

        return address;
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = EthereumAddress.fromHex(wallet.data.address).hexEip55;

      // TODO: remove this
      // final DBWallet dbwallet = DBWallet(
      //   type: 'regular',
      //   name: name,
      //   address: address,
      //   publicKey: wallet.data.publicKey,
      //   balance: 0,
      //   wallet: jsonEncode(wallet.data.wallet),
      //   locked: true,
      // );

      // await _db.wallet.create(dbwallet);

      await _preferences.setLastWallet(address);

      _appState.importLoadingSuccess();

      return address;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return null;
  }

  Future<QRWallet?> importWebWallet(String qrWallet) async {
    try {
      _appState.importLoadingReq();

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      _appState.importLoadingSuccess();

      return wallet;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return null;
  }

  void copyPasswordToClipboard() {
    Clipboard.setData(ClipboardData(text: _appState.walletPassword));
    _appState.hasCopied(true);
  }

  Future<void> clearDataAndBackups() async {
    try {
      _appState.deleteBackupLoadingReq();

      await _encPrefs.deleteWalletBackups();

      await _preferences.clear();

      _appState.deleteBackupLoadingSuccess();
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.deleteBackupLoadingError();
  }

  bool androidBackupIsConfigured() {
    return _preferences.androidBackupIsConfigured;
  }

  Future<bool> configureAndroidBackup() async {
    try {
      await getEncryptedPreferencesService().init(
        AndroidEncryptedPreferencesOptions(),
      );

      _preferences.setAndroidBackupIsConfigured(true);
      return true;
    } catch (e) {
      //
    }

    return false;
  }
}
