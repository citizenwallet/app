import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/account/contacts.dart';
import 'package:citizenwallet/services/db/account/db.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:citizenwallet/services/cache/contacts.dart';
import 'package:web3dart/web3dart.dart';

class ProfilesLogic extends WidgetsBindingObserver {
  final AccountDBService _db = AccountDBService();
  final AccountBackupDBService _accountBackupDBService =
      AccountBackupDBService();
  late ProfilesState _state;

  late EthPrivateKey _currentCredentials;
  late EthereumAddress _currentAccount;
  late Config _currentConfig;

  late Debounce debouncedSearchProfile;

  late Debounce debouncedLoad;
  List<String> toLoad = [];
  bool stopLoading = false;
  bool _isInitialized = false;

  ProfilesLogic(BuildContext context) {
    _state = context.read<ProfilesState>();

    debouncedLoad = debounce(
      _loadProfile,
      const Duration(milliseconds: 500),
      leading: true,
    );

    debouncedSearchProfile = debounce(
      (String username) {
        _searchProfile(username);
      },
      const Duration(milliseconds: 250),
    );
  }

  void setWalletState(
      Config config, EthPrivateKey credentials, EthereumAddress account) {
    _currentConfig = config;
    _currentCredentials = credentials;
    _currentAccount = account;
    _isInitialized = true;
  }

  Future<ProfileV1?> _loadCachedProfile(String addr) async {
    try {
      if (_currentConfig == null || !_isInitialized) {
        return null;
      }

      final cachedProfile = await ContactsCache().get(addr, () async {
        final fetchedProfile = await getProfile(_currentConfig, addr);
        if (fetchedProfile == null) {
          return null;
        }

        return DBContact(
          account: fetchedProfile.account,
          username: fetchedProfile.username,
          name: fetchedProfile.name,
          description: fetchedProfile.description,
          image: fetchedProfile.image,
          imageMedium: fetchedProfile.imageMedium,
          imageSmall: fetchedProfile.imageSmall,
        );
      });

      if (cachedProfile != null) {
        final profile = ProfileV1.fromMap(cachedProfile.toMap());

        return profile;
      }
    } catch (exception) {
      //
    }

    return null;
  }

  _loadProfile() async {
    if (stopLoading) {
      return;
    }

    if (!_isInitialized) {
      return;
    }

    final toLoadCopy = [...toLoad];
    toLoad = [];

    for (final addr in toLoadCopy) {
      if (stopLoading) {
        return;
      }
      try {
        final profile = await _loadCachedProfile(addr);

        if (profile != null) {
          _state.isLoading(addr);

          await delay(const Duration(milliseconds: 250));

          _state.isLoaded(addr, profile);
          continue;
        }
      } catch (exception) {
        //
      }

      await delay(const Duration(milliseconds: 125));
      _state.isError(addr);
    }
  }

  Future<void> loadProfile(String addr) async {
    try {
      if (!_isInitialized) {
        return;
      }

      if (!toLoad.contains(addr) && !_state.exists(addr)) {
        toLoad.add(addr);
        debouncedLoad();
      }
    } catch (exception) {
      //
    }
  }

  Future<void> _searchProfile(String value) async {
    try {
      if (_currentConfig == null || !_isInitialized) {
        _state.isSearchingError();
        return;
      }

      final cleanValue = value.replaceFirst('@', '');

      _state.isSearching();

      final profile = cleanValue.startsWith('0x')
          ? await getProfile(_currentConfig, cleanValue)
          : await getProfileByUsername(_currentConfig, cleanValue);

      if (profile != null) {
        _state.isSearchingSuccess(profile, []);
        await _db.contacts.upsert(DBContact(
          account: profile.account,
          username: profile.username,
          name: profile.name,
          description: profile.description,
          image: profile.image,
          imageMedium: profile.imageMedium,
          imageSmall: profile.imageSmall,
        ));
      } else {
        if (cleanValue.length >= 3) {
          final results = await _db.contacts.search(cleanValue.toLowerCase());
          _state.isSearchingSuccess(
              null, results.map((e) => ProfileV1.fromMap(e.toMap())).toList());
        } else {
          _state.isSearchingSuccess(null, []);
        }
      }
      return;
    } catch (e) {
      //
    }

    _state.isSearchingError();
  }

  Future<ProfileV1?> getLocalProfile(String addr) async {
    try {
      if (!_isInitialized) {
        _state.isSearchingError();
        return null;
      }

      _state.isSearching();

      final profile = await _loadCachedProfile(addr);

      if (profile != null) {
        _state.isSearchingSuccess(profile, []);
        _state.isSelected(null);
        return profile;
      }
    } catch (exception) {
      //
    }

    _state.isSearchingError();
    return null;
  }

  Future<void> searchProfile(String username) async {
    if (username.trim().isEmpty) {
      debouncedSearchProfile.cancel();
      _state.clearSearch();
      return;
    }

    if (!_isInitialized) {
      _state.isSearchingError();
      return;
    }

    _state.isSearching();
    debouncedSearchProfile([username]);
  }

  Future<void> allProfiles() async {
    try {
      if (!_isInitialized) {
        _state.isSearchingError();
        return;
      }

      _state.isSearching();

      final results = await _db.contacts.getAll();

      _state.isSearchingSuccess(
        null,
        results.map((e) => ProfileV1.fromMap(e.toMap())).toList(),
      );
      return;
    } catch (e) {
      //
    }

    _state.isSearchingError();
  }

  Future<void> loadProfiles() async {
    try {
      if (!_isInitialized) {
        _state.profileListFail();
        return;
      }

      _state.profileListRequest();

      final results = await _db.contacts.getAll();

      _state.profileListSuccess(
        results.map((e) => ProfileV1.fromMap(e.toMap())).toList(),
      );
      return;
    } catch (e) {
      //
    }

    _state.profileListFail();
  }

  Future<void> loadProfilesFromAllAccounts() async {
    try {
      if (!_isInitialized) {
        return;
      }

      final accounts = await _accountBackupDBService.accounts.all();
      final profilesMap = <String, ProfileV1>{};

      for (final account in accounts) {
        if (account.profile != null) {
          profilesMap[account.address.hexEip55] = account.profile!;
          _state.isLoaded(account.address.hexEip55, account.profile!);
        }

        // Try to get updated profile from wallet
        final updatedProfile = await getLocalProfile(account.address.hexEip55);

        if (updatedProfile != null) {
          profilesMap[account.address.hexEip55] = updatedProfile;
          _state.isLoaded(account.address.hexEip55, updatedProfile);
          await _accountBackupDBService.accounts.update(
            DBAccount(
              alias: account.alias,
              address: account.address,
              name: updatedProfile.name,
              username: updatedProfile.username,
              accountFactoryAddress: account.accountFactoryAddress,
              profile: updatedProfile,
            ),
          );
        }
      }

      _state.profileListSuccess(profilesMap.values.toList());
    } catch (_) {
      //
    }
  }

  void selectProfile(ProfileV1? profile) {
    if (!_isInitialized) {
      return;
    }

    _state.isSelected(profile);
  }

  Future<String?> getAccountAddressWithAlias(String alias) async {
    if (!_isInitialized) {
      return null;
    }

    try {
      final accounts =
          await _accountBackupDBService.accounts.allForAlias(alias);
      return accounts.first.address.hex;
    } catch (e) {
      return null;
    }
  }

  Future<ProfileV1?> getSendToProfile(String address) async {
    if (!_isInitialized) {
      return null;
    }

    final profile = await getLocalProfile(address);
    return profile;
  }

  void deSelectProfile() {
    if (!_isInitialized) {
      return;
    }

    _state.isDeSelected();
  }

  void clearSearch({bool notify = true}) {
    if (!_isInitialized) {
      return;
    }

    debouncedSearchProfile.cancel();

    _state.clearSearch(notify: notify);
  }

  void pause() {
    debouncedLoad.cancel();
    stopLoading = true;
  }

  void resume() {
    stopLoading = false;

    if (!_isInitialized) {
      return;
    }

    debouncedLoad();
  }

  void dispose() {
    _state.clearSearch(notify: false);
    _state.clearProfiles();
    debouncedSearchProfile.cancel();
    pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        pause();
        break;
      default:
        resume();
    }
  }
}
