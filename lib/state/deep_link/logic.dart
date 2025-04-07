import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/deep_link/state.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class DeepLinkLogic {
  final DeepLinkState _state;
  final WalletService _wallet;
  final NotificationsLogic _notifications;

  DeepLinkLogic(BuildContext context, WalletService wallet)
      : _state = context.read<DeepLinkState>(),
        _wallet = wallet,
        _notifications = NotificationsLogic(context);

  Future<void> faucetV1Redeem(String params) async {
    try {
      _state.request();

      final uri = Uri(query: params);

      final address = uri.queryParameters['address'];
      if (address == null) {
        throw Exception('Address is required');
      }

      final calldata = await _wallet.simpleFaucetRedeemCallData(address);

      final (_, userop) = await _wallet.prepareUserop([address], [calldata]);

      final txHash = await _wallet.submitUserop(userop);
      if (txHash == null) {
        throw Exception('transaction failed');
      }

      final success = await _wallet.waitForTxSuccess(txHash);
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
      _state.request();

      final uri = Uri(query: params);

      final address = uri.queryParameters['address'];
      if (address == null) {
        throw Exception('Address is required');
      }

      final amount = await _wallet.getFaucetRedeemAmount(address);

      _state.setFaucetAmount(amount);
      _state.success();
      return;
    } catch (_) {}
    _state.fail();
  }
}
