import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/audio/audio.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/db/accounts.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:web3dart/web3dart.dart';

class AppLogic {
  final PreferencesService _preferences = PreferencesService();
  final AccountsServiceInterface _accounts = getAccountsService();
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

  void loadApp() {
    _appState.loadApp();
  }

  void appLoaded() {
    _appState.appLoaded();
  }

  void setFirstLaunch(bool firstLaunch) {
    try {
      _preferences.setFirstLaunch(firstLaunch);
    } catch (e) {
      //
    }
  }

  Future<(String?, String?)> loadLastWallet() async {
    try {
      _appState.importLoadingReq();
      final String? lastWallet = _preferences.lastWallet;
      final String? lastAlias = _preferences.lastAlias;

      DBAccount? dbWallet;
      if (lastWallet != null && lastAlias != null) {
        dbWallet = await _accounts.getAccount(lastWallet, lastAlias);
      }

      if (dbWallet == null) {
        // attempt to see if there are any other wallets backed up
        final dbWallets = await _accounts.getAllAccounts();

        if (dbWallets.isNotEmpty) {
          final dbWallet = dbWallets[0];

          final address = dbWallet.address.hexEip55;

          await _preferences.setLastWallet(address);
          await _preferences.setLastAlias(dbWallet.alias);

          _appState.importLoadingSuccess();

          return (address, dbWallet.alias);
        }

        _appState.importLoadingError();

        return (null, null);
      }

      await delay(
          const Duration(milliseconds: 1500)); // smoother launch experience

      _appState.importLoadingSuccess();

      final address = dbWallet.address.hexEip55;

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

  Future<List<CWWallet>> loadWalletsFromAlias(String alias) async {
    try {
      _appState.importLoadingReq();

      final dbWallets = await _accounts.getAccountsForAlias(alias);

      await delay(
          const Duration(milliseconds: 500)); // smoother launch experience

      final config = await _config.getConfig(alias);

      _appState.importLoadingSuccess();

      return dbWallets.map((e) {
        final credentials = e.privateKey;

        return CWWallet(
          '0.0',
          name: e.name,
          address: credentials?.address.hexEip55 ?? '',
          alias: config.community.alias,
          account: e.address.hexEip55,
          currencyName: config.token.name,
          symbol: config.token.symbol,
          currencyLogo: config.community.logo,
          decimalDigits: config.token.decimals,
          locked: false,
        );
      }).toList();
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _appState.importLoadingError();

    return [];
  }

  Future<String?> createWallet(String alias) async {
    try {
      _appState.importLoadingReq();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      final config = await _config.getConfig(alias);

      final accFactory = await accountFactoryServiceFromConfig(config);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      await _accounts.setAccount(DBAccount(
        address: address,
        privateKey: credentials,
        name: config.token.name,
        alias: config.community.alias,
      ));

      await _preferences.setLastWallet(address.hexEip55);
      await _preferences.setLastAlias(config.community.alias);

      _appState.importLoadingSuccess();

      return address.hexEip55;
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

      final config = await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'));

      final accFactory = await accountFactoryServiceFromConfig(config);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      _appState.importLoadingWebSuccess(password);

      return 'v3-${base64Encode('$address|${wallet.toJson()}'.codeUnits)}';
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

      final config = await _config.getConfig(alias);

      final name = 'Imported ${config.token.symbol} Account';

      final accFactory = await accountFactoryServiceFromConfig(config);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      await _accounts.setAccount(
        DBAccount(
          address: address,
          privateKey: credentials,
          name: name,
          alias: config.community.alias,
        ),
      );

      await _preferences.setLastWallet(address.hexEip55);
      await _preferences.setLastAlias(config.community.alias);

      _appState.importLoadingSuccess();

      return address.hexEip55;
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
          base64Decode(webWallet.replaceFirst('v3-', '')));

      final decodedSplit = decoded.split('|');

      if (decodedSplit.length != 2) {
        throw Exception('invalid format');
      }

      final password = dotenv.get('WEB_BURNER_PASSWORD');

      final wallet = Wallet.fromJson(decodedSplit[1], password);

      final credentials = wallet.privateKey;

      final config = await _config.getConfig(alias);

      final address = EthereumAddress.fromHex(decodedSplit[0]);

      final existing =
          await _accounts.getAccount(address.hexEip55, config.community.alias);
      if (existing != null) {
        return (existing.address.hexEip55, alias);
      }

      await _accounts.setAccount(
        DBAccount(
          address: address,
          privateKey: credentials,
          name: '${config.token.symbol} Web Account',
          alias: config.community.alias,
        ),
      );

      await _preferences.setLastWallet(address.hexEip55);
      await _preferences.setLastAlias(config.community.alias);

      _appState.importLoadingSuccess();

      return (address.hexEip55, alias);
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

      await _accounts.deleteAllAccounts();

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
      // await getAccountsService().init(
      //   AndroidAccountsOptions(accountsDB: _dbAccounts),
      // );

      _preferences.setAndroidBackupIsConfigured(true);
      return true;
    } catch (_) {
      //
    }

    return false;
  }

  void setLanguageCode(int selectedItem) {
    try {
      if (selectedItem < 0 || selectedItem >= languageOptions.length) {
        return;
      }

      final language = languageOptions[selectedItem];

      _preferences.setLanguageCode(language.code);
      _appState.setSelectedLanguage(language);
    } catch (e) {
      //
    }
  }
}
