import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/db/account/contacts.dart';
import 'package:citizenwallet/services/db/account/db.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/services/db/backup/accounts.dart';
import 'package:citizenwallet/services/db/backup/db.dart';
import 'package:citizenwallet/services/photos/photos.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/utils/random.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

class ProfileLogic {
  final String deepLinkURL = dotenv.get('ORIGIN_HEADER');

  final AppDBService _appDBService = AppDBService();
  final AccountBackupDBService _accountBackupDBService =
      AccountBackupDBService();

  late ProfileState _state;
  late ProfilesState _profiles;
  final PhotosService _photos = PhotosService();

  final AccountDBService _db = AccountDBService();
  Config? _config;
  EthPrivateKey? _credentials;
  EthereumAddress? _account;

  bool _pauseProfileCreation = false;

  ProfileLogic(BuildContext context) {
    _state = context.read<ProfileState>();
    _profiles = context.read<ProfilesState>();
  }

  void setWalletState(
      Config config, EthPrivateKey credentials, EthereumAddress account) {
    _config = config;
    _credentials = credentials;
    _account = account;
  }

  void resetAll() {
    _state.resetAll();
  }

  void resetEdit() {
    _state.resetEditForm();
  }

  void resetViewProfile() {
    _state.resetViewProfile();
  }

  void startEdit() async {
    if (_state.image == '') {
      _state.startEdit(null, null);
      return;
    }

    try {
      final isNetwork = _state.image.startsWith('http');
      if (isNetwork) {
        _state.startEdit(null, null);
        return;
      }

      final (b, ext) = await _photos.photoToData(_state.image);
      _state.startEdit(convertBytesToUint8List(b), ext);
    } catch (e) {
      //
    }
  }

  Future<void> loadProfileLink() async {
    try {
      _state.setProfileLinkRequest();

      if (_account == null || _config == null) {
        throw Exception('account or config not found');
      }

      final community = await _appDBService.communities.get(_account!.hexEip55);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final url = communityConfig.community.walletUrl(deepLinkURL);

      final compressedParams = compress(
          '?address=${_account!.hexEip55}&alias=${communityConfig.community.alias}');

      _state.setProfileLinkSuccess('$url&receiveParams=$compressedParams');
      return;
    } catch (e) {
      //
    }

    _state.setProfileLinkError();
  }

  void copyProfileLink() {
    Clipboard.setData(ClipboardData(text: _state.profileLink));
  }

  void clearProfileLink() {
    _state.clearProfileLink();
  }

  Future<void> selectPhoto() async {
    try {
      final result = await _photos.selectPhoto();

      if (result != null) {
        _state.setEditImage(result.$1, result.$2);
      }
    } catch (_) {}
  }

  Future<void> checkUsername(String username) async {
    if (username == '') {
      _state.setUsernameError();
    }

    if (username == _state.username) {
      return;
    }

    if (_config == null) {
      _state.setUsernameError();
      return;
    }

    try {
      _state.setUsernameRequest();

      final exists = await profileExists(_config!, username);
      if (exists) {
        throw Exception('Already exists');
      }

      _state.setUsernameSuccess();
      return;
    } catch (exception) {
      //
    }

    _state.setUsernameError();
  }

  Future<void> loadProfile({String? account, bool online = false}) async {
    if (_account == null || _config == null) {
      print('ProfileLogic.loadProfile: _account or _config is null');
      return;
    }
    
    final ethAccount = _account!;
    final alias = _config!.community.alias;
    final acc = account ?? ethAccount.hexEip55;

    print('ProfileLogic.loadProfile: Loading profile for account $acc, alias $alias, online: $online');

    resume();

    try {
      _state.setProfileRequest();

      final account =
          await _accountBackupDBService.accounts.get(ethAccount, alias);

      print('ProfileLogic.loadProfile: Found account in DB: ${account != null}');
      print('ProfileLogic.loadProfile: Account has profile: ${account?.profile != null}');

      if (account != null && account.profile != null) {
        final profile = account.profile!;
        print('ProfileLogic.loadProfile: Setting profile from DB - username: ${profile.username}');
        _state.setProfileSuccess(
          account: profile.account,
          username: profile.username,
          name: profile.name,
          description: profile.description,
          image: profile.image,
          imageMedium: profile.imageMedium,
          imageSmall: profile.imageSmall,
        );

        _profiles.isLoaded(
          profile.account,
          profile,
        );
      }

      if (!online) {
        print('ProfileLogic.loadProfile: Community is offline, exiting');
        throw Exception('community is offline');
      }

      print('ProfileLogic.loadProfile: Fetching profile from network');
      final profile = await getProfile(_config!, acc);
      print('ProfileLogic.loadProfile: Network profile found: ${profile != null}');
      
      if (profile == null) {
        print('ProfileLogic.loadProfile: No network profile found, current username: ${_state.username}');
        _state.setProfileNoChangeSuccess();
        
        // Only generate a new username if we don't already have one
        if (_state.username.isEmpty) {
          print('ProfileLogic.loadProfile: Generating new username');
          giveProfileUsername();
        } else {
          print('ProfileLogic.loadProfile: Keeping existing username: ${_state.username}');
        }

        return;
      }

      profile.name = cleanNameString(profile.name);

      print('ProfileLogic.loadProfile: Setting profile from network - username: ${profile.username}');
      _state.setProfileSuccess(
        account: profile.account,
        username: profile.username,
        name: profile.name,
        description: profile.description,
        image: profile.image,
        imageMedium: profile.imageMedium,
        imageSmall: profile.imageSmall,
      );

      _profiles.isLoaded(
        profile.account,
        profile,
      );

      _accountBackupDBService.accounts.update(DBAccount(
        alias: alias,
        address: ethAccount,
        name: profile.name,
        username: profile.username,
        privateKey: null,
        profile: profile,
      ));

      return;
    } catch (exception) {
      //
    }

    _state.setProfileError();
  }

  Future<void> loadViewProfile(String account) async {
    try {
      _state.viewProfileRequest();

      final cachedProfile = _profiles.profiles.containsKey(account)
          ? _profiles.profiles[account]
          : null;

      if (cachedProfile?.profile != null) {
        _state.viewProfileSuccess(cachedProfile!.profile);
      }

      final profile = await getProfile(_config!, account);
      if (profile == null) {
        await delay(const Duration(milliseconds: 500));
        _state.setViewProfileNoChangeSuccess();
        return;
      }

      profile.name = cleanNameString(profile.name);

      _state.viewProfileSuccess(profile);

      _profiles.isLoaded(
        profile.account,
        profile,
      );

      return;
    } catch (exception) {
      //
    }

    _state.viewProfileError();
  }

  Future<bool> save(ProfileV1 profile, Uint8List? image) async {
    if (_config == null || _account == null || _credentials == null) {
      return false;
    }

    try {
      _state.setProfileRequest();

      await delay(const Duration(milliseconds: 250));

      profile.username = _state.usernameController.value.text.toLowerCase();
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final exists = await createAccount(_config!, _account!, _credentials!);
      if (!exists) {
        throw Exception('Failed to create account');
      }

      _state.setProfileUploading();

      final Uint8List newImage = image != null
          ? convertBytesToUint8List(image)
          : await _photos.photoFromBundle('assets/icons/profile.jpg');

      final url = await setProfile(
        _config!,
        _account!,
        _credentials!,
        ProfileRequest.fromProfileV1(profile),
        image: newImage,
        fileType: '.jpg',
      );
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await getProfileFromUrl(_config!, url);
      if (newProfile == null) {
        throw Exception('Failed to load profile');
      }

      _state.viewProfileSuccess(newProfile);

      _state.setProfileSuccess(
        account: newProfile.account,
        username: newProfile.username,
        name: newProfile.name,
        description: newProfile.description,
        image: newProfile.image,
        imageMedium: newProfile.imageMedium,
        imageSmall: newProfile.imageSmall,
      );

      _db.contacts.upsert(
        DBContact(
          account: newProfile.account,
          username: newProfile.username,
          name: newProfile.name,
          description: newProfile.description,
          image: newProfile.image,
          imageMedium: newProfile.imageMedium,
          imageSmall: newProfile.imageSmall,
        ),
      );

      _accountBackupDBService.accounts.update(
        DBAccount(
          alias: _config!.community.alias,
          address: EthereumAddress.fromHex(newProfile.account),
          name: newProfile.name,
          username: newProfile.username,
          privateKey: null,
          profile: newProfile,
        ),
      );

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      return true;
    } catch (_) {}

    _state.setProfileError();
    return false;
  }

  Future<bool> update(ProfileV1 profile) async {
    if (_config == null || _account == null || _credentials == null) {
      return false;
    }

    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text.toLowerCase();
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;
      profile.image = _state.image;
      profile.imageMedium = _state.imageMedium;
      profile.imageSmall = _state.imageSmall;

      _state.setProfileExisting();

      final existing = await getProfile(_config!, profile.account);
      if (existing == null) {
        throw Exception('Failed to load profile');
      }

      if (existing == profile) {
        _state.setProfileNoChangeSuccess();
        return true;
      }

      _state.setProfileUploading();

      final url =
          await updateProfile(_config!, _account!, _credentials!, profile);
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await getProfileFromUrl(_config!, url);
      if (newProfile == null) {
        throw Exception('Failed to load profile');
      }

      _state.viewProfileSuccess(newProfile);

      _state.setProfileSuccess(
        account: newProfile.account,
        username: newProfile.username,
        name: newProfile.name,
        description: newProfile.description,
        image: newProfile.image,
        imageMedium: newProfile.imageMedium,
        imageSmall: newProfile.imageSmall,
      );

      _db.contacts.upsert(DBContact(
        account: newProfile.account,
        username: newProfile.username,
        name: newProfile.name,
        description: newProfile.description,
        image: newProfile.image,
        imageMedium: newProfile.imageMedium,
        imageSmall: newProfile.imageSmall,
      ));

      _accountBackupDBService.accounts.update(
        DBAccount(
          alias: _config!.community.alias,
          address: EthereumAddress.fromHex(newProfile.account),
          name: newProfile.name,
          username: newProfile.username,
          privateKey: null,
          profile: newProfile,
        ),
      );

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      return true;
    } catch (_) {}

    _state.setProfileError();
    return false;
  }

  void updateNameErrorState(String name) {
    _state.setNameError(name.isEmpty);
  }

  void updateDescriptionText(String desc) {
    _state.setDescriptionText(desc);
  }

  Future<String?> generateProfileUsername() async {
    if (_config == null) {
      return null;
    }

    String username = await getRandomUsername();
    _state.setUsernameSuccess(username: username);

    const maxTries = 3;
    const baseDelay = Duration(milliseconds: 100);

    for (int tries = 1; tries <= maxTries; tries++) {
      final exists = await profileExists(_config!, username);

      if (!exists) {
        return username;
      }

      if (tries > maxTries) break;

      username = await getRandomUsername();
      await delay(baseDelay * tries);
    }

    return null;
  }

  Future<void> giveProfileUsername() async {
    debugPrint('handleNewProfile');

    if (_config == null || _account == null || _credentials == null) {
      return;
    }

    try {
      final username = await generateProfileUsername();
      if (username == null) {
        _state.setUsernameSuccess(username: '@anonymous');
        return;
      }

      _state.setUsernameSuccess(username: username);

      final address = _account!.hexEip55;
      final alias = _config!.community.alias;

      final account = await _accountBackupDBService.accounts
          .get(EthereumAddress.fromHex(address), alias);

      if (account == null) {
        throw Exception(
            'acccount with address $address and alias $alias not found in db/backup/accounts table');
      }

      account.profile?.updateUsername(username);

      ProfileV1 profile = account.profile ??
          ProfileV1(
            account: address,
            username: username,
            name: account.name,
          );

      _profiles.isLoaded(
        profile.account,
        profile,
      );

      if (_pauseProfileCreation) {
        return;
      }

      final exists = await createAccount(_config!, _account!, _credentials!);
      if (!exists) {
        throw Exception('Failed to create account');
      }

      if (_pauseProfileCreation) {
        return;
      }

      final url = await setProfile(
        _config!,
        _account!,
        _credentials!,
        ProfileRequest.fromProfileV1(profile),
        image: await _photos.photoFromBundle('assets/icons/profile.jpg'),
        fileType: '.jpg',
      );
      if (url == null) {
        throw Exception('Failed to create profile url');
      }

      if (_pauseProfileCreation) {
        return;
      }

      final newProfile = await getProfileFromUrl(_config!, url);
      if (newProfile == null) {
        throw Exception('Failed to get profile from url $url');
      }

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      if (_pauseProfileCreation) {
        return;
      }

      _db.contacts.upsert(
        DBContact(
          account: newProfile.account,
          username: newProfile.username,
          name: newProfile.name,
          description: newProfile.description,
          image: newProfile.image,
          imageMedium: newProfile.imageMedium,
          imageSmall: newProfile.imageSmall,
        ),
      );

      if (_pauseProfileCreation) {
        return;
      }

      _accountBackupDBService.accounts.update(
        DBAccount(
          alias: alias,
          address: EthereumAddress.fromHex(address),
          name: newProfile.name,
          username: newProfile.username,
          profile: newProfile,
        ),
      );
    } catch (e, s) {
      debugPrint('giveProfileUsername error: $e, $s');
    }
  }

  void pause() {
    _pauseProfileCreation = true;
  }

  void resume() {
    _pauseProfileCreation = false;
  }
}
