import 'package:citizenwallet/services/wallet/wallet2.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

class ProfilesLogic {
  late ProfilesState _state;
  final WalletService2 _wallet = WalletService2();

  late Debounce debouncedLoad;
  List<String> toLoad = [];

  ProfilesLogic(BuildContext context) {
    _state = context.read<ProfilesState>();

    debouncedLoad = debounce(
      _loadProfile,
      const Duration(milliseconds: 500),
    );
  }

  _loadProfile() async {
    final toLoadCopy = [...toLoad];
    toLoad = [];

    for (final addr in toLoadCopy) {
      try {
        _state.isLoading(addr);

        final profile = await _wallet.getProfile(addr);

        if (profile != null) {
          _state.isLoaded(addr, profile);
          await delay(const Duration(milliseconds: 125));
          return;
        }
      } catch (exception) {
        //
      }

      _state.isError(addr);
      await delay(const Duration(milliseconds: 125));
    }
  }

  Future<void> loadProfile(String addr) async {
    try {
      if (!toLoad.contains(addr) && !_state.exists(addr)) {
        toLoad.add(addr);
        debouncedLoad();
      }
    } catch (exception) {
      //
    }
  }
}
