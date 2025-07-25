import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class DeepLinkLogic {
  final DeepLinkState _state;
  final NotificationsLogic _notifications;
  late Config _config;
  late EthPrivateKey _credentials;
  late EthereumAddress _account;

  DeepLinkLogic(BuildContext context, Config config, EthPrivateKey credentials, EthereumAddress account)
      : _state = context.read<DeepLinkState>(),
        _notifications = NotificationsLogic(context) {
    _config = config;
    _credentials = credentials;
    _account = account;
  }

  void setWalletState(Config config, EthPrivateKey credentials, EthereumAddress account) {
    _config = config;
    _credentials = credentials;
    _account = account;
  }

  Future<void> faucetV1Redeem(String params) async {
    try {
      if (_config == null || _credentials == null || _account == null) {
        throw Exception('Wallet not initialized');
      }

      _state.request();

      final uri = Uri(query: params);

      final address = uri.queryParameters['address'];
      if (address == null) {
        throw Exception('Address is required');
      }

      final calldata = await simpleFaucetRedeemCallData(_config, address);

      final (_, userop) = await prepareUserop(
        _config,
        _account,
        _credentials,
        [address],
        [calldata],
      );

      final txHash = await submitUserop(_config, userop);
      if (txHash == null) {
        throw Exception('transaction failed');
      }

      final success = await waitForTxSuccess(_config, txHash);
      if (!success) {
        throw Exception('transaction failed');
      }

      _notifications.toastShow('Faucet claim request made');

      _state.success();
      return;
    } catch (_) {}
    _state.fail();
  }

  Future<void> faucetV1Metadata(String params) async {
    try {
      if (_config == null) {
        throw Exception('Wallet not initialized');
      }

      _state.request();

      final uri = Uri(query: params);

      final address = uri.queryParameters['address'];
      if (address == null) {
        throw Exception('Address is required');
      }

      final amount = await getFaucetRedeemAmount(_config, address);

      _state.setFaucetAmount(amount);
      _state.success();
      return;
    } catch (_) {}
    _state.fail();
  }
}
