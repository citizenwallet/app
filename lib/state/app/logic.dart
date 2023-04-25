import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/db/db.dart';
import 'package:citizenwallet/services/db/wallet.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/qr/qr.dart';
import 'package:citizenwallet/services/wallet/models/qr/wallet.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class AppLogic {
  final PreferencesService _preferences = PreferencesService();
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

      if (lastWallet == null) {
        return null;
      }

      await _db.wallet.getWallet(lastWallet);

      await delay(const Duration(milliseconds: 250));

      _appState.importLoadingSuccess();

      return lastWallet;
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

      _appState.importLoadingSuccess();

      return credentials.address.hex;
    } catch (e) {
      print(e);
    }

    _appState.importLoadingError();

    return null;
  }

  Future<QRWallet?> importWallet(String qrWallet, String name) async {
    try {
      _appState.importLoadingReq();

      final QRWallet wallet = QR.fromCompressedJson(qrWallet).toQRWallet();

      await wallet.verifyData();

      final address = wallet.data.address.toLowerCase();

      final DBWallet dbwallet = DBWallet(
        id: 0,
        type: 'regular',
        name: name,
        address: address,
        balance: 0,
        wallet: jsonEncode(wallet.data.wallet),
      );

      await _db.wallet.create(dbwallet);

      await _preferences.setLastWallet(address);

      _appState.importLoadingSuccess();

      return wallet;
    } catch (e) {
      print(e);
    }

    _appState.importLoadingError();

    return null;
  }
}
