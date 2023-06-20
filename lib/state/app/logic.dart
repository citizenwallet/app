import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class AppLogic {
  final PreferencesService _preferences = PreferencesService();
  final EncryptedPreferencesService _encPrefs = EncryptedPreferencesService();
  late AppState _appState;
  final DBService _db = DBService();

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
    } catch (e) {
      print(e);
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

          await _preferences.setLastWallet(dbWallet.address);

          _appState.importLoadingSuccess();

          return dbWallet.address;
        }

        throw Exception('No wallet backup');
      }

      await delay(const Duration(milliseconds: 250));

      _appState.importLoadingSuccess();

      return dbWallet.address;
    } catch (e) {
      print(e);
    }

    _appState.importLoadingError();

    return null;
  }

  Future<bool> isVerifiedWallet(String qrWallet) async {
    try {
      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      return wallet.verifyData();
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<String?> createWallet(String name) async {
    try {
      _appState.importLoadingReq();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      await _encPrefs.setWalletBackup(BackupWallet(
        address: credentials.address.hex,
        privateKey: (bytesToHex(credentials.privateKey)),
        name: name,
      ));

      await _preferences.setLastWallet(credentials.address.hex);

      _appState.importLoadingSuccess();

      return credentials.address.hex;
    } catch (e) {
      print(e);
    }

    _appState.importLoadingError();

    return null;
  }

  Future<String?> getLastEncodedWallet() async {
    try {
      final String? lastWallet = _preferences.lastWalletLink;

      if (lastWallet == null) {
        throw Exception('No last wallet');
      }

      return lastWallet;
    } catch (e) {
      print(e);
    }

    return null;
  }

  Future<QRWallet?> createWebWallet() async {
    try {
      _appState.importLoadingWebReq();

      await delay(const Duration(milliseconds: 250));

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final password = dotenv.get('WEB_BURNER_PASSWORD');

      final Wallet wallet =
          Wallet.createNew(credentials, password, Random.secure());

      await delay(const Duration(milliseconds: 250));

      _appState.importLoadingWebSuccess(password);

      return QRWallet(
          raw: QRWalletData(
        wallet: jsonDecode(wallet.toJson()),
        address: credentials.address.hex,
        publicKey: wallet.privateKey.encodedPublicKey,
      ).toJson());
    } catch (e) {
      print(e);
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

        await _encPrefs.setWalletBackup(
          BackupWallet(
            address: credentials.address.hex,
            privateKey: bytesToHex(credentials.privateKey),
            name: name,
          ),
        );

        await _preferences.setLastWallet(credentials.address.hex);

        _appState.importLoadingSuccess();

        return credentials.address.hex;
      }

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = wallet.data.address.toLowerCase();

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
    } catch (e) {
      print(e);
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
    } catch (e) {
      print(e);
    }

    _appState.importLoadingError();

    return null;
  }

  void copyPasswordToClipboard() {
    Clipboard.setData(ClipboardData(text: _appState.walletPassword));
    _appState.hasCopied(true);
  }
}
