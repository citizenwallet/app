import 'package:citizenwallet/services/wallet/wallet2.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProfilesLogic {
  late ProfilesState _state;
  final WalletService2 _wallet = WalletService2();

  ProfilesLogic(BuildContext context) {
    _state = context.read<ProfilesState>();
  }

  Future<void> loadProfile(String addr) async {
    try {
      _state.isLoading(addr);

      final profile = await _wallet.getProfile(addr);

      if (profile != null) _state.isLoaded(addr, profile);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.isError(addr);
  }
}
