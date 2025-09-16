import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/cache/contacts.dart';
import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/account/db.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/db/account/transactions.dart';
import 'package:citizenwallet/services/accounts/accounts.dart';
import 'package:citizenwallet/services/engine/events.dart';
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/sigauth/sigauth.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/engine/utils.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/theme/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/qr.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:citizenwallet/state/wallet_connect/logic.dart';

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
  final WalletState _state;
  final ThemeLogic _theme = ThemeLogic();
  final NotificationsLogic _notificationsLogic;
  final WalletKitLogic _walletKitLogic = WalletKitLogic();

  final String defaultAlias = dotenv.get('DEFAULT_COMMUNITY_ALIAS');
  final String deepLinkURL = dotenv.get('ORIGIN_HEADER');
  final String appUniversalURL = dotenv.get('ORIGIN_HEADER');

  final ConfigService _config = ConfigService();
  final WalletService _wallet = WalletService();
  final AccountDBService _accountDBService = AccountDBService();
  final AppDBService _appDBService = AppDBService();

  final PreferencesService _preferences = PreferencesService();
  final AccountsServiceInterface _encPrefs = getAccountsService();

  bool cancelLoadAccounts = false;

  WalletService get wallet => _wallet;
  EventService? _eventService;
  SigAuthConnection get connection => _wallet.connection;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TextEditingController get addressController => _addressController;
  TextEditingController get amountController => _amountController;
  TextEditingController get messageController => _messageController;

  String? get lastWallet => _preferences.lastWallet;
  String get address => _wallet.address.hexEip55;
  String get account => _wallet.account.hexEip55;
  String get token => _wallet.tokenAddress;

  WalletLogic(BuildContext context, NotificationsLogic notificationsLogic)
      : _state = context.read<WalletState>(),
        _notificationsLogic = notificationsLogic {
    _walletKitLogic.setContext(context);
  }

  EthPrivateKey get privateKey {
    return _wallet.credentials;
  }

  void updateMessage() {
    _state.updateMessage(_messageController.value.text);
  }

  void startListeningMessage() {
    _messageController.addListener(updateMessage);
  }

  void stopListeningMessage() {
    _messageController.removeListener(updateMessage);
  }

  void updateListenerAmount() {
    _state.updateAmount(_amountController.value.text);
  }

  void startListeningAmount() {
    _amountController.addListener(updateAmount);
  }

  void stopListeningAmount() {
    _amountController.removeListener(updateAmount);
  }

  Future<void> resetWalletPreferences() async {
    try {
      await _preferences.clear();

      return;
    } catch (_) {}
  }

  Future<void> fetchWalletConfig() async {
    try {
      final config =
          await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'), null);

      _state.setWalletConfig(config);

      return;
    } catch (_) {}
  }

  Future<(bool, bool)> openWalletFromURL(
    String encodedWallet, {
    Future<void> Function()? loadAdditionalData,
    void Function()? goBackHome,
  }) async {
    String encoded = encodedWallet;
    String password = '';

    bool fromLegacy = false;

    try {
      password = dotenv.get('WEB_BURNER_PASSWORD');

      if (!encoded.startsWith('v3-')) {
        // old format, convert
        throw Exception('old format');
      }
    } catch (_) {
      if (!encoded.startsWith('v2-')) {
        // something is wrong with the encoding

        // try and reset preferences so we don't end up in a loop
        await resetWalletPreferences();

        // go back to the home screen
        if (goBackHome != null) goBackHome();
        return (false, true);
      }
      fromLegacy = true;

      // old format, convert
      final decoded = convertUint8ListToString(
          base64Decode(encoded.replaceFirst('v2-', '')));

      if (password.isEmpty) {
        return (false, false);
      }

      Wallet cred = Wallet.fromJson(decoded, password);

      final config =
          await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'), null);

      // load the legacy account factory
      final accFactory = await accountFactoryServiceFromConfig(config,
          customAccountFactory: dotenv.get('WEB_LEGACY_ACCOUNT_FACTORY'));
      final address =
          await accFactory.getAddress(cred.privateKey.address.hexEip55);

      // construct the new encoded url
      encoded = 'v3-${base64Encode('$address|${cred.toJson()}'.codeUnits)}';
    }

    if (password.isEmpty) {
      return (false, false);
    }

    try {
      _state.loadWallet();
      _state.setWalletReady(false);
      _state.setWalletReadyLoading(true);

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      final decoded = convertUint8ListToString(
          base64Decode(encoded.replaceFirst('v3-', '')));
      final decodedSplit = decoded.split('|');

      if (decodedSplit.length != 2) {
        throw Exception('invalid format');
      }

      await delay(const Duration(milliseconds: 0));

      Wallet cred = Wallet.fromJson(decodedSplit[1], password);

      await delay(const Duration(milliseconds: 0));

      final config =
          await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'), null);

      final token = config.getPrimaryToken();

      await _wallet.initWeb(
        EthereumAddress.fromHex(decodedSplit[0]),
        cred.privateKey,
        legacy: fromLegacy,
        NativeCurrency(
          name: token.name,
          symbol: token.symbol,
          decimals: token.decimals,
        ),
        config,
      );

      await _accountDBService.init(
          'wallet_${_wallet.address.hexEip55}'); // TODO: migrate to account address instead

      ContactsCache().init(_accountDBService);

      final currency = _wallet.currency;

      _state.setWalletConfig(config);

      _state.setWallet(
        CWWallet(
          '0',
          name:
              'Citizen Wallet', // on web, acts as a page's title, wallet is fitting here
          address: _wallet.address.hexEip55,
          alias: config.community.alias,
          account: _wallet.account.hexEip55,
          currencyName: token.name,
          symbol: token.symbol,
          currencyLogo: config.community.logo,
          decimalDigits: currency.decimals,
          locked: false,
          minter: false,
        ),
      );

      _wallet.getBalance().then((v) => _state.setWalletBalance(v));
      _wallet.minter.then((v) => _state.setWalletMinter(v));

      if (loadAdditionalData != null) await loadAdditionalData();

      _theme.changeTheme(config.community.theme);

      await _preferences.setLastWallet(_wallet.address.hexEip55);
      await _preferences.setLastAlias(config.community.alias);
      await _preferences.setLastWalletLink(encoded);

      _state.loadWalletSuccess();
      _state.setWalletReady(true);
      _state.setWalletReadyLoading(false);

      return (true, false);
    } catch (_) {}

    _state.loadWalletError();
    _state.setWalletReady(false);
    _state.setWalletReadyLoading(false);
    return (false, false);
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
      final String? accAddress = paramAddress ?? _preferences.lastWallet;
      String alias = paramAlias ?? _preferences.lastAlias ?? defaultAlias;

      if (accAddress == null) {
        throw Exception('address not found');
      }

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);
      _theme.changeTheme(communityConfig.community.theme);

      final dbWallet = await _encPrefs.getAccount(accAddress, alias);

      if (dbWallet == null || dbWallet.privateKey == null) {
        throw NotFoundException();
      }

      final token = communityConfig.getPrimaryToken();

      final nativeCurrency = NativeCurrency(
        name: token.name,
        symbol: token.symbol,
        decimals: token.decimals,
      );

      if (isWalletLoaded &&
          accAddress == _wallet.account.hexEip55 &&
          alias == _wallet.alias) {
        _wallet.getBalance().then((v) {
          _state.updateWalletBalanceSuccess(v);
        });

        _state.loadWalletSuccess();

        await loadAdditionalData(false);

        _theme.changeTheme(communityConfig.community.theme);

        await _preferences.setLastWallet(address);
        await _preferences.setLastAlias(alias);

        return address;
      }

      _state.loadWallet();
      _state.setWalletReady(false);
      _state.setWalletReadyLoading(true);

      final int chainId = _preferences.chainId;

      _state.setChainId(chainId);

      await _wallet.init(
        dbWallet.address,
        dbWallet.privateKey!,
        nativeCurrency,
        communityConfig,
        onNotify: (String message) {
          _notificationsLogic.show(message);
        },
        onFinished: (bool ok) {
          _state.setWalletReady(ok);
          _state.setWalletReadyLoading(false);
        },
      );

      await _accountDBService.init(
          'wallet_${_wallet.address.hexEip55}'); // TODO: migrate to account address instead

      ContactsCache().init(_accountDBService);

      _config
          .isCommunityOnline(
              communityConfig.chains[token.chainId.toString()]!.node.url)
          .then((isOnline) {
        communityConfig.online = isOnline;

        _state.setWalletConfig(communityConfig);

        _appDBService.communities
            .updateOnlineStatus(communityConfig.community.alias, isOnline);
      });

      _state.setWallet(
        CWWallet(
          '0',
          name: dbWallet.name,
          address: dbWallet.address.hexEip55,
          alias: dbWallet.alias,
          account: _wallet.account.hexEip55,
          currencyName: token.name,
          symbol: token.symbol,
          currencyLogo: communityConfig.community.logo,
          decimalDigits: nativeCurrency.decimals,
          locked: dbWallet.privateKey == null,
          plugins: communityConfig.plugins ?? [],
          minter: false,
        ),
      );

      _wallet.getBalance().then((v) => _state.setWalletBalance(v));

      loadAdditionalData(true);

      _state.loadWalletSuccess();

      await _preferences.setLastWallet(accAddress);
      await _preferences.setLastAlias(communityConfig.community.alias);

      return accAddress;
    } on NotFoundException {
      _state.loadWalletError(exception: NotFoundException());

      return null;
    } catch (e, s) {
      print('error: $e');
      print('stack: $s');
    }

    _state.loadWalletError();
    _state.setWalletReady(false);
    _state.setWalletReadyLoading(false);
    return null;
  }

  bool get isOnline => _eventService != null && !_eventService!.isOffline;

  Future<String?> createWallet(String alias) async {
    try {
      _state.createWallet();

      final credentials = EthPrivateKey.createRandom(Random.secure());

      // final config = await _config.getConfig(alias);

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final accFactory = await accountFactoryServiceFromConfig(communityConfig);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      _state.setWalletConfig(communityConfig);

      final token = communityConfig.getPrimaryToken();

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: 'New ${token.symbol} Account',
        address: credentials.address.hexEip55,
        alias: communityConfig.community.alias,
        account: address.hexEip55,
        currencyName: token.name,
        symbol: token.symbol,
        currencyLogo: communityConfig.community.logo,
        locked: false,
      );

      await _encPrefs.setAccount(DBAccount(
        address: address,
        privateKey: credentials,
        name: 'New ${token.symbol} Account',
        alias: communityConfig.community.alias,
      ));

      _theme.changeTheme(communityConfig.community.theme);

      await _preferences.setLastWallet(address.hexEip55);
      await _preferences.setLastAlias(communityConfig.community.alias);

      _state.createWalletSuccess(
        cwwallet,
      );

      return address.hexEip55;
    } catch (_) {}

    _state.createWalletError();

    return null;
  }

  Future<String?> importWallet(String qrWallet, String alias) async {
    try {
      _state.createWallet();

      // check if it is a private key and create a new wallet from the private key with auto-password
      final isPrivateKey = isValidPrivateKey(qrWallet);
      if (!isPrivateKey) {
        return null;
      }
      final credentials = stringToPrivateKey(qrWallet);
      if (credentials == null) {
        throw Exception('Invalid private key');
      }

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final token = communityConfig.getPrimaryToken();

      final accFactory = await accountFactoryServiceFromConfig(communityConfig);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      final name = 'Imported ${token.symbol} Account';

      _state.setWalletConfig(communityConfig);

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: credentials.address.hexEip55,
        alias: communityConfig.community.alias,
        account: address.hexEip55,
        currencyName: token.name,
        symbol: token.symbol,
        currencyLogo: communityConfig.community.logo,
        locked: false,
      );

      await _encPrefs.setAccount(DBAccount(
        address: address,
        privateKey: credentials,
        name: name,
        alias: communityConfig.community.alias,
      ));

      _theme.changeTheme(communityConfig.community.theme);

      await _preferences.setLastWallet(address.hexEip55);
      await _preferences.setLastAlias(communityConfig.community.alias);

      _state.createWalletSuccess(cwwallet);

      return address.hexEip55;
    } catch (_) {}

    _state.createWalletError();

    return null;
  }

  Future<void> editWallet(String address, String alias, String name) async {
    try {
      final dbWallet = await _encPrefs.getAccount(address, alias);
      if (dbWallet == null) {
        throw NotFoundException();
      }

      await _encPrefs.setAccount(DBAccount(
        address: EthereumAddress.fromHex(address),
        privateKey: dbWallet.privateKey,
        name: name,
        alias: dbWallet.alias,
      ));

      loadDBWallets();

      if (_state.wallet?.address == address) {
        // only update current name if it's the same wallet
        _state.updateCurrentWalletName(name);
      }

      return;
    } on NotFoundException {
      // HANDLE
    } catch (_) {}

    _state.createWalletError();
  }

  Future<void> transferEventSubscribe() async {
    try {
      final alias = _wallet.alias;
      if (alias == null) {
        return;
      }

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        return;
      }

      Config communityConfig = Config.fromJson(community.config);

      final token = communityConfig.getPrimaryToken();

      if (_eventService != null) {
        await _eventService!.disconnect();
        handleEventServiceIntentionalDisconnect(true);
        _eventService = null;
      }

      _eventService = EventService(
        communityConfig.chains[token.chainId.toString()]!.node.wsUrl,
        token.address,
        _wallet.transferEventSignature,
      );

      _eventService!.setMessageHandler(handleTransferEvent);
      _eventService!.setStateHandler(handleEventServiceStateChange);

      await _eventService!.connect();
      handleEventServiceIntentionalDisconnect(false);

      return;
    } catch (_) {}
  }

  Future<void> transferEventUnsubscribe() async {
    if (_eventService != null) {
      await _eventService!.disconnect();
      handleEventServiceIntentionalDisconnect(true);
      _eventService = null;
    }
  }

  void handleEventServiceStateChange(EventServiceState state) {
    _state.setEventServiceState(state);
  }

  void handleEventServiceIntentionalDisconnect(bool intentionalDisconnect) {
    _state.setEventServiceIntentionalDisconnect(intentionalDisconnect);
  }

  void handleTransferEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'remove':
        break;
      case 'new':
      case 'update':
        final log = Log.fromJson(event.data);

        final tx = TransferEvent.fromLog(log, standard: _wallet.standard);

        // TODO: fix this on the websocket side
        final myAccount = _wallet.account.hexEip55;
        if (tx.from.hexEip55 != myAccount && tx.to.hexEip55 != myAccount) {
          return;
        }
        ///////////////////////////////////////

        _accountDBService.transactions.insert(DBTransaction(
          hash: tx.hash,
          txHash: tx.txhash,
          tokenId: tx.tokenId.toString(),
          createdAt: tx.createdAt,
          from: tx.from.hexEip55,
          to: tx.to.hexEip55,
          nonce: "0", // TODO: remove nonce hardcode
          value: tx.value.toString(),
          data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
          status: tx.status,
          contract: _wallet.tokenAddress,
        ));

        final txList = [
          CWTransaction(
            fromDoubleUnit(
              tx.value.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tx.hash,
            hash: tx.txhash,
            chainId: _wallet.chainId,
            from: tx.from.hexEip55,
            to: tx.to.hexEip55,
            description: tx.data?.description ?? '',
            date: tx.createdAt,
          ),
        ];

        if (_state.inProgressTransaction != null) {
          if (_state.inProgressTransaction!.hash == tx.txhash &&
              tx.status == 'success') {
            final successTransaction = CWTransaction(
              _state.inProgressTransaction!.amount,
              id: _state.inProgressTransaction!.id,
              hash: tx.txhash,
              chainId: _state.inProgressTransaction!.chainId,
              from: _state.inProgressTransaction!.from,
              to: _state.inProgressTransaction!.to,
              description: _state.inProgressTransaction!.description,
              date: _state.inProgressTransaction!.date,
              state: TransactionState.success,
            );
            _state.setInProgressTransaction(successTransaction);
          }
        }

        incomingTxNotification(txList.where((element) =>
            element.to == _wallet.account.hexEip55 &&
            element.state != TransactionState.success));

        _state.incomingTransactionsRequestSuccess(txList);

        updateBalance();

        break;
      default:
        break;
    }
  }

  int _incomingTxCount = 0;
  // CWTransaction? _lastIncomingTx;

  void incomingTxNotification(Iterable<CWTransaction> incomingTx) {
    final incomingTxCount = incomingTx.length;

    if (incomingTxCount > 0 && incomingTxCount > _incomingTxCount) {
      // _lastIncomingTx = incomingTx.first;
      _notificationsLogic.show(
        'Receiving ${incomingTx.first.amount} ${_wallet.currency.symbol}...',
      );
    }

    // if (_lastIncomingTx != null && incomingTxCount < _incomingTxCount) {
    //   _notificationsLogic.show(
    //     '${_lastIncomingTx!.amount} ${_wallet.currency.symbol} is now in your account.',
    //     playSound: true,
    //   );
    //   _lastIncomingTx = null;
    // }

    _incomingTxCount = incomingTxCount;
  }

  // takes a password and returns a wallet
  Future<String?> returnWallet(String address, String alias) async {
    try {
      final dbWallet = await _encPrefs.getAccount(address, alias);
      if (dbWallet == null || dbWallet.privateKey == null) {
        throw NotFoundException();
      }

      return bytesToHex(dbWallet.privateKey!.privateKey);

      // TODO: export to web instead of returning private key
      // final credentials = EthPrivateKey.fromHex(dbWallet.privateKey);

      // await delay(const Duration(milliseconds: 0));

      // final password = dotenv.get('WEB_BURNER_PASSWORD');

      // final Wallet wallet = Wallet.createNew(
      //   credentials,
      //   password,
      //   Random.secure(),
      //   scryptN:
      //       512, // TODO: increase factor if we can threading >> https://stackoverflow.com/questions/11126315/what-are-optimal-scrypt-work-factors
      // );

      // await delay(const Duration(milliseconds: 0));

      // final config = await _config.getConfig(alias);

      // final domainPrefix = config.community.customDomain ??
      //     '${config.community.alias}.citizenwallet.xyz';

      // return 'https://$domainPrefix/wallet/v3-${base64Encode('$address|${wallet.toJson()}'.codeUnits)}';
    } catch (_) {}

    return null;
  }

  // permanently deletes a wallet
  Future<void> deleteWallet(String address, String alias) async {
    try {
      await _encPrefs.deleteAccount(address, alias);

      loadDBWallets();

      return;
    } catch (_) {}

    _state.createWalletError();
  }

  Future<void> loadTransactions() async {
    try {
      _state.loadTransactions();

      // with network errors or bugs there can be a build up of invalid transactions that will never return
      // clear the old ones out when the user pulls to refresh
      await _accountDBService.transactions.clearOldTransactions();

      _state.clearTemporaryTransactions();

      transferEventUnsubscribe();

      final maxDate = DateTime.now().toUtc();

      const limit = 10;

      final List<CWTransaction> txs =
          (await _accountDBService.transactions.getPreviousTransactions(
        maxDate,
        _wallet.tokenAddress,
        "0", // TODO: remove tokenId hardcode
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
                    description: dbtx.data != ''
                        ? TransferData.fromJson(jsonDecode(dbtx.data))
                            .description
                        : '',
                    date: dbtx.createdAt,
                    state: TransactionState.values.firstWhereOrNull(
                          (v) => v.name == dbtx.status,
                        ) ??
                        TransactionState.success,
                  ))
              .toList();

      if (txs.isEmpty || (txs.isNotEmpty && txs.first.date.isBefore(maxDate))) {
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
              tokenId: tx.tokenId.toString(),
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: "0", // TODO: remove nonce hardcode
              value: tx.value.toString(),
              data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
              status: tx.status,
              contract: _wallet.tokenAddress,
            ),
          );

          await _accountDBService.transactions.insertAll(
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
                description: dbtx.data != ''
                    ? TransferData.fromJson(jsonDecode(dbtx.data)).description
                    : '',
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

      _wallet.getBalance().then((v) {
        _state.updateWalletBalanceSuccess(v);
      });

      await transferEventSubscribe();

      return;
    } catch (_) {}

    _state.loadTransactionsError();
  }

  Future<void> loadAdditionalTransactions(int limit) async {
    try {
      _state.loadAdditionalTransactions();

      final maxDate = _state.transactionsMaxDate;
      final offset = _state.transactionsOffset + limit;

      final List<CWTransaction> txs =
          (await _accountDBService.transactions.getPreviousTransactions(
        maxDate,
        _wallet.tokenAddress,
        "0", // TODO: remove tokenId hardcode
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
                    description: dbtx.data != ''
                        ? TransferData.fromJson(jsonDecode(dbtx.data))
                            .description
                        : '',
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
              tokenId: tx.tokenId.toString(),
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: "0", // TODO: remove nonce hardcode
              value: tx.value.toString(),
              data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
              status: tx.status,
              contract: _wallet.tokenAddress,
            ),
          );

          await _accountDBService.transactions.insertAll(
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
                description: dbtx.data != ''
                    ? TransferData.fromJson(jsonDecode(dbtx.data)).description
                    : '',
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
    } catch (_) {}

    _state.loadAdditionalTransactionsError();
  }

  Future<void> updateBalance() async {
    try {
      if (_wallet.alias == null) {
        throw Exception('alias not found');
      }

      final balance = await _wallet.getBalance();

      final currentDoubleBalance =
          double.tryParse(_state.wallet?.balance ?? '0.0') ?? 0.0;
      final doubleBalance = double.tryParse(balance) ?? 0.0;

      if (currentDoubleBalance != doubleBalance) {
        // there was a change in balance
        HapticFeedback.lightImpact();

        _state.updateWalletBalanceSuccess(balance, notify: true);
      }
      return;
    } catch (_) {}

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

    final txHash = await sendTransactionFromLocked(
      tx.amount,
      tx.to,
      message: tx.description,
    );

    return txHash != null;
  }

  Future<String?> sendTransaction(
    String amount,
    String to, {
    String message = '',
    String? id,
    bool clearInProgress = false,
  }) async {
    return kIsWeb
        ? sendTransactionFromUnlocked(
            amount,
            to,
            message: message,
            id: id,
            clearInProgress: clearInProgress,
          )
        : sendTransactionFromLocked(amount, to,
            message: message, id: id, clearInProgress: clearInProgress);
  }

  bool isInvalidAmount(String amount, {unlimited = false}) {
    if (unlimited) {
      return false;
    }

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

  void preSendingTransaction(
    BigInt amount,
    String tempId,
    String to,
    String from, {
    String message = '',
  }) {
    _state.setInProgressTransaction(
      CWTransaction.sending(
        fromDoubleUnit(
          amount.toString(),
          decimals: _wallet.currency.decimals,
        ),
        id: tempId,
        hash: '',
        chainId: _wallet.chainId,
        from: from,
        to: to,
        description: message,
        date: DateTime.now(),
      ),
    );
  }

  void sendingTransaction(
    BigInt amount,
    String hash,
    String to,
    String from, {
    String message = '',
  }) {
    _state.setInProgressTransaction(
      CWTransaction.pending(
        fromDoubleUnit(
          amount.toString(),
          decimals: _wallet.currency.decimals,
        ),
        id: hash,
        hash: '',
        chainId: _wallet.chainId,
        to: to,
        from: from,
        description: message,
        date: DateTime.now(),
      ),
    );
  }

  Future<String?> sendTransactionFromLocked(
    String amount,
    String to, {
    String message = '',
    String? id,
    bool clearInProgress = false,
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

      preSendingTransaction(
        parsedAmount,
        tempId,
        to,
        _wallet.account.hexEip55,
        message: message,
      );

      // TODO: token id should be set
      final calldata = _wallet.tokenTransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.tokenAddress],
        [calldata],
      );

      final args = {
        'from': _wallet.account.hexEip55,
        'to': to,
      };
      if (_wallet.standard == 'erc1155') {
        args['operator'] = _wallet.account.hexEip55;
        args['id'] = '0';
        args['amount'] = parsedAmount.toString();
      } else {
        args['value'] = parsedAmount.toString();
      }

      final eventData = createEventData(
        stringSignature: _wallet.transferEventStringSignature,
        topic: _wallet.transferEventSignature,
        args: args,
      );

      final txHash = await _wallet.submitUserop(
        userop,
        data: eventData,
        extraData: message != '' ? TransferData(message) : null,
      );
      if (txHash == null) {
        // this is an optional operation
        throw Exception('transaction failed');
      }

      sendingTransaction(
        parsedAmount,
        tempId,
        to,
        _wallet.account.hexEip55,
        message: message,
      );

      if (userop.isFirst()) {
        // an account was created, update push token in the background
        _wallet.waitForTxSuccess(txHash).then((value) {
          if (!value) {
            return;
          }

          // the account exists, enable push notifications
          _notificationsLogic.updatePushToken();
        });
      }

      clearInputControllers();
      _state.sendTransactionSuccess(null);

      if (_state.inProgressTransaction != null) {
        final successTransaction = CWTransaction(
          _state.inProgressTransaction!.amount,
          id: _state.inProgressTransaction!.id,
          hash: txHash,
          chainId: _state.inProgressTransaction!.chainId,
          from: _state.inProgressTransaction!.from,
          to: _state.inProgressTransaction!.to,
          description: _state.inProgressTransaction!.description,
          date: _state.inProgressTransaction!.date,
          state: TransactionState.success,
        );
        _state.setInProgressTransaction(successTransaction);
      }

      if (clearInProgress) {
        _state.clearInProgressTransaction(notify: true);
      }

      return txHash;
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
            description: message,
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
            description: message,
            date: DateTime.now(),
            error: NetworkInvalidBalanceException().message),
      );
    } catch (e, s) {
      print('error: $e');
      print('stack: $s');
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            description: message,
            date: DateTime.now(),
            error: NetworkUnknownException().message),
      );
    }

    _state.sendTransactionError();

    return null;
  }

  Future<String?> sendCallDataTransaction(
    String to,
    String value,
    String data,
  ) async {
    try {
      _state.sendCallDataTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      final calldata = hexToBytes(data);

      final (hash, userop) = await _wallet.prepareUserop(
        [to],
        [calldata],
        value: BigInt.parse(value.isEmpty ? '0' : value),
      );

      final txHash = await _wallet.submitUserop(
        userop,
      );
      if (txHash == null) {
        // this is an optional operation
        throw Exception('transaction failed');
      }

      if (userop.isFirst()) {
        // an account was created, update push token in the background
        _wallet.waitForTxSuccess(txHash).then((value) {
          if (!value) {
            return;
          }

          // the account exists, enable push notifications
          _notificationsLogic.updatePushToken();
        });
      }

      clearInputControllers();

      _state.sendCallDataTransactionSuccess();

      return txHash;
    } on NetworkCongestedException {
      //
    } on NetworkInvalidBalanceException {
      //
    } catch (e, s) {
      print('error: $e');
      print('stack: $s');
    }

    _state.sendCallDataTransactionError();

    return null;
  }

  Future<String?> sendTransactionFromUnlocked(
    String amount,
    String to, {
    String message = '',
    String? id,
    bool clearInProgress = false,
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

      preSendingTransaction(
        parsedAmount,
        tempId,
        to,
        _wallet.account.hexEip55,
      );

      // TODO: token id should be set
      final calldata = _wallet.tokenTransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.tokenAddress],
        [calldata],
      );

      final args = {
        'from': _wallet.account.hexEip55,
        'to': to,
      };
      if (_wallet.standard == 'erc1155') {
        args['operator'] = _wallet.account.hexEip55;
        args['id'] = '0';
        args['amount'] = parsedAmount.toString();
      } else {
        args['value'] = parsedAmount.toString();
      }

      final eventData = createEventData(
        stringSignature: _wallet.transferEventStringSignature,
        topic: _wallet.transferEventSignature,
        args: args,
      );

      final txHash = await _wallet.submitUserop(
        userop,
        data: eventData,
        extraData: message != '' ? TransferData(message) : null,
      );
      if (txHash == null) {
        // this is an optional operation
        throw Exception('transaction failed');
      }

      sendingTransaction(
        parsedAmount,
        tempId,
        to,
        _wallet.account.hexEip55,
        message: message,
      );

      if (userop.isFirst()) {
        // an account was created, update push token in the background
        _wallet.waitForTxSuccess(txHash).then((value) {
          if (!value) {
            return;
          }

          // the account exists, enable push notifications
          _notificationsLogic.updatePushToken();
        });
      }

      clearInputControllers();

      _state.sendTransactionSuccess(null);
      if (clearInProgress) {
        _state.clearInProgressTransaction(notify: true);
      }

      return txHash;
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
            description: message,
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
            description: message,
            date: DateTime.now(),
            error: NetworkInvalidBalanceException().message),
      );
    } catch (_) {
      _state.sendQueueAddTransaction(
        CWTransaction.failed(
            fromDoubleUnit(
              parsedAmount.toString(),
              decimals: _wallet.currency.decimals,
            ),
            id: tempId,
            hash: '',
            to: to,
            description: message,
            date: DateTime.now(),
            error: NetworkUnknownException().message),
      );
    }

    _state.sendTransactionError();

    return null;
  }

  void clearInProgressTransaction({bool notify = false}) {
    _state.clearInProgressTransaction(notify: notify);
  }

  Future<bool> mintTokens(String amount, String to,
      {String message = '', String? id}) async {
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

      preSendingTransaction(
        parsedAmount,
        tempId,
        to,
        zeroAddress,
        message: message,
      );

      // TODO: token id should be set
      final calldata = _wallet.tokenMintCallData(
        to,
        parsedAmount,
      );

      final (_, userop) = await _wallet.prepareUserop(
        [_wallet.tokenAddress],
        [calldata],
      );

      final args = {
        'from': zeroAddress,
        'to': to,
      };
      if (_wallet.standard == 'erc1155') {
        args['operator'] = _wallet.account.hexEip55;
        args['id'] = '0';
        args['amount'] = parsedAmount.toString();
      } else {
        args['value'] = parsedAmount.toString();
      }

      final eventData = createEventData(
        stringSignature: _wallet.transferEventStringSignature,
        topic: _wallet.transferEventSignature,
        args: args,
      );

      final txHash = await _wallet.submitUserop(
        userop,
        data: eventData,
        extraData: message != '' ? TransferData(message) : null,
      );
      if (txHash == null) {
        // this is an optional operation
        throw Exception('transaction failed');
      }

      sendingTransaction(
        parsedAmount,
        tempId,
        to,
        zeroAddress,
        message: message,
      );

      if (userop.isFirst()) {
        // an account was created, update push token in the background
        _wallet.waitForTxSuccess(txHash).then((value) {
          if (!value) {
            return;
          }

          // the account exists, enable push notifications
          _notificationsLogic.updatePushToken();
        });
      }

      clearInputControllers();

      _state.sendTransactionSuccess(null);

      return true;
    } on NetworkCongestedException {
      //
    } on NetworkInvalidBalanceException {
      //
    } catch (_) {}

    _state.setInProgressTransactionError(
      CWTransaction.failed(
        fromDoubleUnit(
          amount.toString(),
          decimals: _wallet.currency.decimals,
        ),
        id: tempId,
        hash: '',
        chainId: _wallet.chainId,
        to: to,
        from: zeroAddress,
        description: message.isNotEmpty ? message : 'Failed to mint token',
        date: DateTime.now(),
      ),
    );

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

  void clearAmountController() {
    _amountController.clear();
  }

  void resetInputErrorState() {
    _state.resetInvalidInputs();
  }

  void updateAddress({bool override = false}) {
    if (override) {
      _state.setHasAddress(true);
      return;
    }

    final parsedData = parseQRCode(_addressController.text);
    _state.setHasAddress(parsedData.address.isNotEmpty);
  }

  void setInvalidAddress() {
    _state.setInvalidAddress(true);
  }

  void updateAmount({bool unlimited = false}) {
    _state.setHasAmount(
      _amountController.text.isNotEmpty,
      isInvalidAmount(_amountController.value.text, unlimited: unlimited),
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
    } catch (_) {}

    _addressController.text = '';
    _state.parseQRAddressError();
  }

  Future<String?> updateFromCapture(String raw) async {
    try {
      if (raw.isEmpty) {
        throw QREmptyException();
      }

      final format = parseQRFormat(raw);
      if (format == QRFormat.unsupported || format == QRFormat.voucher) {
        throw QRInvalidException();
      }

      final parsedData = parseQRCode(raw);
      if (parsedData.address == '') {
        throw QRInvalidException();
      }

      if (format == QRFormat.sendtoUrlWithEIP681 && parsedData.alias != null) {
        try {
          final community =
              await _appDBService.communities.get(parsedData.alias!);
          if (community == null) {
            throw Exception('Community not found');
          }

          final config = Config.fromJson(community.config);
          final token = config.getPrimaryToken();

          if (!raw.contains('eip681=')) {
            return null;
          }

          final uri = Uri.parse(raw);
          final eip681Param = uri.queryParameters['eip681'];
          if (eip681Param == null) {
            return null;
          }

          final decodedEIP681 = Uri.decodeComponent(eip681Param);
          if (!decodedEIP681.contains('@')) {
            return null;
          }

          final chainIdPart = decodedEIP681.split('@')[1].split('/')[0];
          final chainId = int.tryParse(chainIdPart);
          if (chainId == null || chainId == token.chainId) {
            return null;
          }

          _notificationsLogic
              .show('Wrong chain ID. Expected ${token.chainId}, got $chainId');
          throw QRInvalidException();
        } catch (e) {
          if (e is QRInvalidException) {
            rethrow;
          }
          _notificationsLogic
              .show('Invalid token contract or community configuration');
          throw QRInvalidException();
        }
      }

      if (parsedData.amount != null) {
        if (format == QRFormat.eip681Transfer) {
          final amount = fromDoubleUnit(
            parsedData.amount!,
            decimals: _wallet.currency.decimals,
          );
          _amountController.text = amount;
        } else {
          _amountController.text = parsedData.amount!;
        }
        updateAmount();
      }

      String addressToUse = '';
      try {
        EthereumAddress.fromHex(parsedData.address).hexEip55;
        addressToUse = parsedData.address;
      } catch (_) {
        String username = parsedData.address;
        ProfileV1? profile = await _wallet.getProfileByUsername(username);
        if (profile != null) {
          addressToUse = profile.account;
        } else {
          addressToUse = parsedData.address;
        }
      }

      updateAddressFromHexCapture(addressToUse);

      if (parsedData.description != null) {
        _messageController.text = parsedData.description!;
      } else {
        _messageController.text = parseMessageFromReceiveParams(raw) ?? '';
      }

      // Handle tip information if present
      if (parsedData.tip != null) {
        _state.setTipTo(parsedData.tip!.to);
        _state.setHasTip(true);
      }

      return addressToUse;
    } on QREmptyException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRInvalidException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRAliasMismatchException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } on QRMissingAddressException catch (e) {
      _state.setInvalidScanMessage(e.message);
    } catch (_) {
      //
    }

    return null;
  }

  void updateReceiveQR({bool? onlyHex}) async {
    try {
      updateListenerAmount();

      if (_wallet.alias == null) {
        throw Exception('alias not found');
      }

      final community = await _appDBService.communities.get(_wallet.alias!);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final url = communityConfig.community.walletUrl(deepLinkURL);

      if (onlyHex != null && onlyHex) {
        _state.updateReceiveQR(
            '$url?sendto=${_wallet.account.hexEip55}@${communityConfig.community.alias}');
        return;
      }

      String params =
          'sendto=${_wallet.account.hexEip55}@${communityConfig.community.alias}';

      if (_amountController.value.text.isNotEmpty) {
        final double amount = _amountController.value.text.isEmpty
            ? 0
            : double.tryParse(
                    _amountController.value.text.replaceAll(',', '.')) ??
                0;

        params += '&amount=${amount.toStringAsFixed(2)}';
      }

      if (_messageController.value.text.isNotEmpty) {
        params += '&description=${_messageController.value.text}';
      }

      // Add tipTo parameter if it exists in the state
      final tipTo = _state.tipTo;
      if (tipTo != null && tipTo.isNotEmpty) {
        params += '&tipTo=$tipTo';
      }

      _state.updateReceiveQR('$url&$params');
      return;
    } catch (_) {}

    _state.clearReceiveQR();
  }

  void copyReceiveQRToClipboard(String qr) {
    Clipboard.setData(ClipboardData(text: qr));
  }

  void updateWalletQR() async {
    try {
      _state.updateWalletQR(_wallet.account.hexEip55);
      return;
    } catch (_) {}

    _state.clearWalletQR();
  }

  void copyWalletQRToClipboard() {
    Clipboard.setData(ClipboardData(text: _state.walletQR));
  }

  void copyWalletAccount() {
    try {
      Clipboard.setData(ClipboardData(text: _wallet.account.hexEip55));
    } catch (_) {}
  }

// TODO: remove this
  Future<String?> tryUnlockWallet(String strwallet, String address) async {
    try {
      // final password =
      //     await AccountsServiceInterface().getWalletPassword(address);

      // if (password == null) {
      //   return null;
      // }

      // // attempt to unlock the wallet
      // Wallet.fromJson(strwallet, password);

      return '';
    } catch (_) {}

    return null;
  }

  Future<void> loadDBWallets() async {
    try {
      _state.loadWallets();

      final wallets = await _encPrefs.getAllAccounts();

      final List<CWWallet> cwwallets = await compute((ws) {
        return ws.where((w) => w.privateKey != null).map((w) {
          final creds = w.privateKey!;
          return CWWallet(
            '0.0',
            name: w.name,
            address: creds.address.hexEip55,
            alias: w.alias,
            account: w.address.hexEip55,
            currencyName: '',
            symbol: '',
            currencyLogo: '',
            locked: false,
          );
        }).toList();
      }, wallets);

      _state.loadWalletsSuccess(cwwallets);
    } catch (_) {}

    _state.loadWalletsError();
  }

  void prepareReplyTransaction(String address) {
    try {
      _addressController.text = address;
      _state.setHasAddress(address.isNotEmpty);
    } catch (_) {}
  }

  void prepareEditQueuedTransaction(String id) {
    final tx = _state.getQueuedTransaction(id);

    if (tx == null) {
      return;
    }

    prepareReplayTransaction(tx.to, amount: tx.amount, message: tx.description);
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
    } catch (_) {}
  }

  Future<(String?, String?, String?)> constructPluginUri(
    PluginConfig pluginConfig,
  ) async {
    try {
      final now = DateTime.now().toUtc().add(const Duration(seconds: 30));

      final redirectUrl = '$appUniversalURL/?alias=${_wallet.alias}';
      final encodedRedirectUrl = Uri.encodeComponent(redirectUrl);

      final parsedURL = Uri.parse(appUniversalURL);

      if (pluginConfig.signature) {
        return (
          '${pluginConfig.url}${pluginConfig.url.contains('?') ? '&' : '?'}${connection.queryParams}',
          parsedURL.scheme != 'https' ? parsedURL.scheme : null,
          redirectUrl,
        );
      }

      return (
        '${pluginConfig.url}?account=${_wallet.account.hexEip55}&expiry=${now.millisecondsSinceEpoch}&redirectUrl=$encodedRedirectUrl&signature=0x123',
        parsedURL.scheme != 'https' ? parsedURL.scheme : null,
        redirectUrl,
      );
    } catch (_) {}

    return (null, null, null);
  }

  Future<PluginConfig?> getPluginConfig(String alias, String params) async {
    try {
      final uri = Uri(query: params);

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      if (communityConfig.plugins?.isEmpty ?? true) {
        return null;
      }

      String? url = uri.queryParameters['url'];
      String? extraParams;
      if (url != null) {
        url = Uri.decodeComponent(url);
      } else {
        final parsedUri = Uri.parse(uri.query);
        url = '${parsedUri.scheme}://${parsedUri.host}${parsedUri.path}';
        extraParams = parsedUri.query;
      }

      final plugin =
          communityConfig.plugins?.firstWhereOrNull((p) => p.url == url);
      if (plugin == null) {
        return null;
      }

      if (extraParams != null) {
        plugin.updateUrl('${plugin.url}?$extraParams');
      }

      return plugin;
    } catch (_) {}

    return null;
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
    } catch (_) {}
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
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        resumeFetching();
        loadTransactions();

        if (_wallet.alias == null) {
          return;
        }

        await updateBalance();

        final community = await _appDBService.communities.get(_wallet.alias!);

        if (community == null) {
          return;
        }

        Config communityConfig = Config.fromJson(community.config);

        final token = communityConfig.getPrimaryToken();

        communityConfig.online = await _config.isCommunityOnline(
            communityConfig.chains[token.chainId.toString()]!.node.url);

        await _appDBService.communities.updateOnlineStatus(
            communityConfig.community.alias, communityConfig.online);

        _state.setWalletConfig(communityConfig);

        break;
      default:
        pauseFetching();
    }
  }

  void launchPluginUrl(String uri) {
    try {
      launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void requestWalletActions() {
    _state.walletActionsRequest();
  }

  Future<void> evaluateWalletActions() async {
    _state.walletActionsRequest();

    _state.walletActions = [];

    List<ActionButton> actionsToAdd = [];

    actionsToAdd.add(ActionButton(
      label: 'Vouchers',
      buttonType: ActionButtonType.vouchers,
    ));

    try {
      final isMinter = await _wallet.minter;
      _state.setWalletMinter(isMinter);

      if (isMinter) {
        actionsToAdd.add(ActionButton(
          label: 'Minter',
          buttonType: ActionButtonType.minter,
        ));
      }
    } catch (_) {}

    try {
      final alias = _wallet.alias ?? "";
      final community = await _appDBService.communities.get(alias);

      if (community != null) {
        Config communityConfig = Config.fromJson(community.config);
        final plugins = communityConfig.plugins;

        if (plugins?.isNotEmpty ?? false) {
          actionsToAdd.add(ActionButton(
            label: 'Plugins',
            buttonType: ActionButtonType.plugins,
          ));
        }
      }
    } catch (_) {}

    if (actionsToAdd.length > 1) {
      actionsToAdd.add(ActionButton(
        label: 'More',
        buttonType: ActionButtonType.more,
      ));
    }

    _state.walletActionsSuccess(actionsToAdd);
  }
}
