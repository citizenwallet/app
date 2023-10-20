import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/encrypted_preferences/android.dart';
import 'package:citizenwallet/services/encrypted_preferences/encrypted_preferences.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/uint8.dart';
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
  final ConfigService _config = ConfigService();
  final AudioService _audio = AudioService();

  late AppState _appState;

  AppLogic(BuildContext context) {
    _appState = context.read<AppState>();
  }

  void setDarkMode(bool darkMode) {
    try {
      _preferences.setDarkMode(darkMode);

      _appState.darkMode = darkMode;
    } catch (e) {
      //
    }
  }

  void setMuted(bool muted) {
    try {
      _preferences.setMuted(muted);

      _audio.setMuted(muted);

      _appState.setMuted(muted);
    } catch (e) {
      //
    }
  }

  void setFirstLaunch(bool firstLaunch) {
    try {
      _preferences.setFirstLaunch(firstLaunch);
    } catch (e) {
      //
    }
  }

  void configureGenericConfig() {
    _config.init(
      dotenv.get('WALLET_CONFIG_URL'),
      'app',
    );
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

  Future<(String?, String?)> loadLastWallet() async {
    try {
      _appState.importLoadingReq();
      final String? lastWallet = _preferences.lastWallet;
      final String? lastAlias = _preferences.lastAlias;

      BackupWallet? dbWallet;
      if (lastWallet != null && lastAlias != null) {
        dbWallet = await _encPrefs.getWalletBackup(lastWallet, lastAlias);
      }

      if (dbWallet == null) {
        // attempt to see if there are any other wallets backed up
        final dbWallets = await _encPrefs.getAllWalletBackups();

        if (dbWallets.isNotEmpty) {
          final dbWallet = dbWallets[0];

          final address = EthereumAddress.fromHex(dbWallet.address).hexEip55;

          await _preferences.setLastWallet(address);
          await _preferences.setLastAlias(dbWallet.alias);

          _appState.importLoadingSuccess();

          return (address, dbWallet.alias);
        }
        // there are no wallets backed up but we have a pin code
        // clean up the pin code and start from scratch
        await _encPrefs
            .init(AndroidEncryptedPreferencesOptions(fromScratch: true));

        _appState.importLoadingError();

        return (null, null);
      }

      await delay(
          const Duration(milliseconds: 1500)); // smoother launch experience

      _appState.importLoadingSuccess();

      final address = EthereumAddress.fromHex(dbWallet.address).hexEip55;

      return (address, dbWallet.alias);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return (null, null);
  }

  Future<String?> createWallet(String alias) async {
    try {
      _appState.importLoadingReq();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final address = credentials.address.hexEip55;

      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      await _encPrefs.setWalletBackup(BackupWallet(
        address: address,
        privateKey: (bytesToHex(credentials.privateKey)),
        name: 'New ${config.token.symbol} Account',
        alias: config.community.alias,
      ));

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

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

  Future<String?> importWallet(
    String qrWallet,
    String alias,
  ) async {
    try {
      _appState.importLoadingReq();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (!isPrivateKey) {
        return null;
      }

      final credentials = stringToPrivateKey(qrWallet);
      if (credentials == null) {
        throw Exception('Invalid private key');
      }

      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      final name = 'Imported ${config.token.symbol} Account';

      final address = credentials.address.hexEip55;

      await _encPrefs.setWalletBackup(
        BackupWallet(
          address: address,
          privateKey: bytesToHex(credentials.privateKey),
          name: name,
          alias: config.community.alias,
        ),
      );

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

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

  Future<(String?, String?)> importWebWallet(
    String webWallet,
    String alias,
  ) async {
    try {
      _appState.importLoadingReq();

      final decoded = convertUint8ListToString(
          base64Decode(webWallet.replaceFirst('v2-', '')));

      final password = dotenv.get('WEB_BURNER_PASSWORD');

      final wallet = Wallet.fromJson(decoded, password);

      final credentials = wallet.privateKey;

      final address = credentials.address.hexEip55;

      _config.init(
        dotenv.get('WALLET_CONFIG_URL'),
        alias,
      );

      final config = await _config.config;

      final existing =
          await _encPrefs.getWalletBackup(address, config.community.alias);
      if (existing != null) {
        return (existing.address, alias);
      }

      await _encPrefs.setWalletBackup(
        BackupWallet(
          address: address,
          privateKey: bytesToHex(credentials.privateKey),
          name: '${config.token.symbol} Web Account',
          alias: config.community.alias,
        ),
      );

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(config.community.alias);

      _appState.importLoadingSuccess();

      return (address, alias);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return (null, null);
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
