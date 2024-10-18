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
import 'package:citizenwallet/services/preferences/preferences.dart';
import 'package:citizenwallet/services/wallet/contracts/account_factory.dart';
import 'package:citizenwallet/services/wallet/contracts/erc20.dart';
import 'package:citizenwallet/services/wallet/models/chain.dart';
import 'package:citizenwallet/services/wallet/models/userop.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/theme/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
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
  String? _fetchRequest;

  WalletService get wallet => _wallet;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  TextEditingController get addressController => _addressController;
  TextEditingController get amountController => _amountController;
  TextEditingController get messageController => _messageController;

  String? get lastWallet => _preferences.lastWallet;
  String get address => _wallet.address.hexEip55;
  String get account => _wallet.account.hexEip55;
  String get token => _wallet.erc20Address;

  WalletLogic(BuildContext context, NotificationsLogic notificationsLogic)
      : _state = context.read<WalletState>(),
        _notificationsLogic = notificationsLogic;

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
      final config = await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'));

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

      final config = await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'));

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

      final config = await _config.getWebConfig(dotenv.get('APP_LINK_SUFFIX'));

      await _wallet.initWeb(
        EthereumAddress.fromHex(decodedSplit[0]),
        cred.privateKey,
        legacy: fromLegacy,
        NativeCurrency(
          name: config.token.name,
          symbol: config.token.symbol,
          decimals: config.token.decimals,
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
          currencyName: config.token.name,
          symbol: config.token.symbol,
          currencyLogo: config.community.logo,
          decimalDigits: currency.decimals,
          locked: false,
          minter: false,
        ),
      );

      _wallet.balance.then((v) => _state.setWalletBalance(v));
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
      final String? address = paramAddress ?? _preferences.lastWallet;
      final String alias = paramAlias ?? _preferences.lastAlias ?? defaultAlias;

      if (address == null) {
        throw Exception('address not found');
      }

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      if (isWalletLoaded &&
          address == _wallet.account.hexEip55 &&
          alias == _wallet.alias) {
        final balance = await _wallet.balance;

        _state.updateWalletBalanceSuccess(balance);

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

      final dbWallet = await _encPrefs.getAccount(address, alias);

      if (dbWallet == null || dbWallet.privateKey == null) {
        throw NotFoundException();
      }

      await _wallet.init(
        dbWallet.address,
        dbWallet.privateKey!,
        NativeCurrency(
          name: communityConfig.token.name,
          symbol: communityConfig.token.symbol,
          decimals: communityConfig.token.decimals,
        ),
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

      final currency = _wallet.currency;

      communityConfig.online =
          await _config.isCommunityOnline(communityConfig.indexer.url);

      await _appDBService.communities.updateOnlineStatus(
          communityConfig.community.alias, communityConfig.online);

      _state.setWalletConfig(communityConfig);

      _state.setWallet(
        CWWallet(
          '0',
          name: dbWallet.name,
          address: _wallet.address.hexEip55,
          alias: dbWallet.alias,
          account: _wallet.account.hexEip55,
          currencyName: communityConfig.token.name,
          symbol: communityConfig.token.symbol,
          currencyLogo: communityConfig.community.logo,
          decimalDigits: currency.decimals,
          locked: dbWallet.privateKey == null,
          plugins: communityConfig.plugins,
          minter: false,
        ),
      );

      _wallet.balance.then((v) => _state.setWalletBalance(v));

      _state.loadWalletSuccess();

      await loadAdditionalData(true);

      _theme.changeTheme(communityConfig.community.theme);

      await _preferences.setLastWallet(address);
      await _preferences.setLastAlias(communityConfig.community.alias);

      return address;
    } on NotFoundException {
      _state.loadWalletError(exception: NotFoundException());

      return null;
    } catch (_) {}

    _state.loadWalletError();
    _state.setWalletReady(false);
    _state.setWalletReadyLoading(false);
    return null;
  }

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

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: 'New ${communityConfig.token.symbol} Account',
        address: credentials.address.hexEip55,
        alias: communityConfig.community.alias,
        account: address.hexEip55,
        currencyName: communityConfig.token.name,
        symbol: communityConfig.token.symbol,
        currencyLogo: communityConfig.community.logo,
        locked: false,
      );

      await _encPrefs.setAccount(DBAccount(
        address: address,
        privateKey: credentials,
        name: 'New ${communityConfig.token.symbol} Account',
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

      final accFactory = await accountFactoryServiceFromConfig(communityConfig);
      final address = await accFactory.getAddress(credentials.address.hexEip55);

      final name = 'Imported ${communityConfig.token.symbol} Account';

      _state.setWalletConfig(communityConfig);

      final CWWallet cwwallet = CWWallet(
        '0.0',
        name: name,
        address: credentials.address.hexEip55,
        alias: communityConfig.community.alias,
        account: address.hexEip55,
        currencyName: communityConfig.token.name,
        symbol: communityConfig.token.symbol,
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

  void transferEventSubscribe() async {
    try {
      _fetchRequest = generateRandomId();

      fetchNewTransfers(_fetchRequest);

      return;
    } catch (_) {}
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

        await delay(txFetchInterval);

        fetchNewTransfers(id);
        return;
      }

      if (txs.isEmpty) {
        // successful but there's nothing

        // still keep balance up to date no matter what
        updateBalance();

        await delay(txFetchInterval);

        fetchNewTransfers(id);
        return;
      }

      final cwtransactions = txs.map(
        (tx) => CWTransaction(
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
          state: TransactionState.values.firstWhereOrNull(
                (v) => v.name == tx.status,
              ) ??
              TransactionState.success,
        ),
      );

      final iterableRemoteTxs = txs.map(
        (tx) => DBTransaction(
          hash: tx.hash,
          txHash: tx.txhash,
          tokenId: tx.tokenId,
          createdAt: tx.createdAt,
          from: tx.from.hexEip55,
          to: tx.to.hexEip55,
          nonce: 0, // TODO: remove nonce hardcode
          value: tx.value.toInt(),
          data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
          status: tx.status,
          contract: _wallet.erc20Address,
        ),
      );

      await _accountDBService.transactions.insertAll(
        iterableRemoteTxs.toList(),
      );

      final txList = cwtransactions.toList();

      final hasChanges = _state.incomingTransactionsRequestSuccess(
        txList,
      );

      incomingTxNotification(txList.where((element) =>
          element.to == _wallet.account.hexEip55 &&
          element.state != TransactionState.success));

      if (hasChanges) {
        updateBalance();
      }

      await delay(txFetchInterval);

      fetchNewTransfers(id);
      return;
    } catch (_) {}

    _state.incomingTransactionsRequestError();
    await delay(txFetchInterval);

    fetchNewTransfers(id);
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

      transferEventUnsubscribe();

      final maxDate = DateTime.now().toUtc();

      const limit = 10;

      final List<CWTransaction> txs =
          (await _accountDBService.transactions.getPreviousTransactions(
        maxDate,
        _wallet.erc20Address,
        0, // TODO: remove tokenId hardcode
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

      if (txs.isEmpty || txs.length < limit) {
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
              tokenId: tx.tokenId,
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: 0, // TODO: remove nonce hardcode
              value: tx.value.toInt(),
              data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
              status: tx.status,
              contract: _wallet.erc20Address,
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

      final balance = await _wallet.balance;

      transferEventSubscribe();

      _state.updateWalletBalanceSuccess(balance);
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
        _wallet.erc20Address,
        0, // TODO: remove tokenId hardcode
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
              tokenId: tx.tokenId,
              createdAt: tx.createdAt,
              from: tx.from.hexEip55,
              to: tx.to.hexEip55,
              nonce: 0, // TODO: remove nonce hardcode
              value: tx.value.toInt(),
              data: tx.data != null ? jsonEncode(tx.data?.toJson()) : '',
              status: tx.status,
              contract: _wallet.erc20Address,
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

      final balance = await _wallet.balance;

      final currentDoubleBalance =
          double.tryParse(_state.wallet?.balance ?? '0.0') ?? 0.0;
      final doubleBalance = double.tryParse(balance) ?? 0.0;

      if (currentDoubleBalance != doubleBalance) {
        // there was a change in balance
        HapticFeedback.lightImpact();

        _state.updateWalletBalanceSuccess(balance, notify: true);
        clearInProgressTransaction();
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

    return sendTransactionFromLocked(
      tx.amount,
      tx.to,
      message: tx.description,
    );
  }

  Future<bool> sendTransaction(String amount, String to,
      {String message = '', String? id}) async {
    return kIsWeb
        ? sendTransactionFromUnlocked(amount, to, message: message, id: id)
        : sendTransactionFromLocked(amount, to, message: message, id: id);
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

  Future<bool> sendTransactionFromLocked(
    String amount,
    String to, {
    String message = '',
    String? id,
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

      final calldata = _wallet.erc20TransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      tempId = hash;

      final txHash = await _wallet.submitUserop(
        userop,
        data: message != '' ? TransferData(message) : null,
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
      );

      tempId = txHash;

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

    return false;
  }

  Future<bool> sendTransactionFromUnlocked(
    String amount,
    String to, {
    String message = '',
    String? id,
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

      final calldata = _wallet.erc20TransferCallData(
        to,
        parsedAmount,
      );

      final (hash, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      tempId = hash;

      final txHash = await _wallet.submitUserop(
        userop,
        data: message != '' ? TransferData(message) : null,
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
      );

      tempId = txHash;

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

    return false;
  }

  void clearInProgressTransaction() {
    _state.clearInProgressTransaction();
  }

  Future<bool> mintTokens(String amount, String to) async {
    final doubleAmount = amount.replaceAll(',', '.');
    final parsedAmount = toUnit(
      doubleAmount,
      decimals: _wallet.currency.decimals,
    );

    try {
      _state.setInProgressTransaction(
        CWTransaction.sending(
          fromDoubleUnit(
            amount.toString(),
            decimals: _wallet.currency.decimals,
          ),
          id: '',
          hash: '',
          chainId: _wallet.chainId,
          to: to,
          from: _wallet.account.hexEip55,
          description: 'Minting tokens',
          date: DateTime.now(),
        ),
      );
      _state.sendTransaction();

      if (to.isEmpty) {
        _state.setInvalidAddress(true);
        throw Exception('invalid address');
      }

      final calldata = _wallet.erc20MintCallData(
        to,
        parsedAmount,
      );

      final (_, userop) = await _wallet.prepareUserop(
        [_wallet.erc20Address],
        [calldata],
      );

      final txHash = await _wallet.submitUserop(
        userop,
      );
      if (txHash == null) {
        // this is an optional operation
        throw Exception('transaction failed');
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
        id: '',
        hash: '',
        chainId: _wallet.chainId,
        to: to,
        from: _wallet.account.hexEip55,
        description: 'Failed to mint token',
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

    final (address, _) = parseQRCode(_addressController.text);
    _state.setHasAddress(address.isNotEmpty);
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
      //
      if (raw.isEmpty) {
        throw QREmptyException();
      }

      final format = parseQRFormat(raw);
      if (format == QRFormat.unsupported || format == QRFormat.voucher) {
        throw QRInvalidException();
      }

      final (address, amount) = parseQRCode(raw);
      if (address == '') {
        throw QRInvalidException();
      }

      if (amount != null) {
        _amountController.text = amount;

        updateAmount();
      }

      updateAddressFromHexCapture(address);

      _messageController.text = parseMessageFromReceiveParams(raw) ?? '';

      return address;
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
        final compressedParams = compress(
            '?address=${_wallet.account.hexEip55}&alias=${communityConfig.community.alias}');

        _state.updateReceiveQR('$url&receiveParams=$compressedParams');
        return;
      }

      String params =
          '?address=${_wallet.account.hexEip55}&alias=${communityConfig.community.alias}';

      if (_amountController.value.text.isNotEmpty) {
        final double amount = _amountController.value.text.isEmpty
            ? 0
            : double.tryParse(
                    _amountController.value.text.replaceAll(',', '.')) ??
                0;

        params += '&amount=${amount.toStringAsFixed(2)}';
      }

      if (_messageController.value.text.isNotEmpty) {
        params += '&message=${_messageController.value.text}';
      }

      final compressedParams = compress(params);

      _state.updateReceiveQR('$url&receiveParams=$compressedParams');
      return;
    } on NotFoundException {
      // HANDLE
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

      String? url = uri.queryParameters['url'];
      if (url == null) {
        return null;
      }

      url = Uri.decodeComponent(url);

      final community = await _appDBService.communities.get(alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      if (communityConfig.plugins.isEmpty) {
        return null;
      }

      final plugin =
          communityConfig.plugins.firstWhereOrNull((p) => p.url == url);
      if (plugin == null) {
        return null;
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
        transferEventSubscribe();

        if (_wallet.alias == null) {
          return;
        }

        await updateBalance();

        final community = await _appDBService.communities.get(_wallet.alias!);

        if (community == null) {
          return;
        }

        Config communityConfig = Config.fromJson(community.config);

        communityConfig.online =
            await _config.isCommunityOnline(communityConfig.indexer.url);

        await _appDBService.communities.updateOnlineStatus(
            communityConfig.community.alias, communityConfig.online);

        _state.setWalletConfig(communityConfig);

        break;
      default:
        transferEventUnsubscribe();
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

        if (plugins.isNotEmpty) {
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
