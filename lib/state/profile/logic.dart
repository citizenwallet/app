import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
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
  final WalletService _wallet = WalletService();

  ProfileLogic(BuildContext context) {
    _state = context.read<ProfileState>();
    _profiles = context.read<ProfilesState>();
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

      if (_wallet.alias == null) {
        throw Exception('alias not found');
      }

      final community = await _appDBService.communities.get(_wallet.alias!);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final url = communityConfig.community.walletUrl(deepLinkURL);

      final compressedParams = compress(
          '?address=${_wallet.account.hexEip55}&alias=${communityConfig.community.alias}');

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

    try {
      _state.setUsernameRequest();

      final exists = await _wallet.profileExists(username);
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

  Future<void> loadProfile({String? account}) async {
    final ethAccount = _wallet.account;
    final alias = _wallet.alias ?? '';
    final acc = account ?? ethAccount.hexEip55;

    try {
      _state.setProfileRequest();

      final dbProfile =
          await _accountBackupDBService.accounts.get(ethAccount, alias);

      if (dbProfile != null && dbProfile.profile != null) {
        final profile = dbProfile.profile!;
        _state.setProfileSuccess(
          account: profile.account,
          username: profile.username,
          name: profile.name,
          description: profile.description,
          image: profile.image,
          imageMedium: profile.imageMedium,
          imageSmall: profile.imageSmall,
        );
      }

      final profile = await _wallet.getProfile(acc);
      if (profile == null) {
        await delay(const Duration(milliseconds: 500));
        _state.setProfileNoChangeSuccess();
        return;
      }

      profile.name = cleanNameString(profile.name);

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

      final profile = await _wallet.getProfile(account);
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
    try {
      _state.setProfileRequest();

      await delay(const Duration(milliseconds: 250));

      profile.username = _state.usernameController.value.text.toLowerCase();
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final exists = await _wallet.createAccount();
      if (!exists) {
        throw Exception('Failed to create account');
      }

      _state.setProfileUploading();

      final Uint8List newImage = image != null
          ? convertBytesToUint8List(image)
          : await _photos.photoFromBundle('assets/icons/profile.jpg');

      final url = await _wallet.setProfile(
        ProfileRequest.fromProfileV1(profile),
        image: newImage,
        fileType: '.jpg',
      );
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await _wallet.getProfileFromUrl(url);
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

      _db.contacts.insert(
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
          alias: _wallet.alias!,
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
    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text.toLowerCase();
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;
      profile.image = _state.image;
      profile.imageMedium = _state.imageMedium;
      profile.imageSmall = _state.imageSmall;

      _state.setProfileExisting();

      final existing = await _wallet.getProfile(profile.account);
      if (existing == null) {
        throw Exception('Failed to load profile');
      }

      debugPrint('existing: ${existing.toJson()}');

      if (existing == profile) {
        _state.setProfileNoChangeSuccess();
        return true;
      }

      _state.setProfileUploading();

      final url = await _wallet.updateProfile(profile);
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await _wallet.getProfileFromUrl(url);
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

      _db.contacts.insert(DBContact(
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
          alias: _wallet.alias!,
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
    String username = getRandomUsername();
    _state.setUsernameSuccess(username: username);

    const maxTries = 3;
    const baseDelay = Duration(milliseconds: 100);

    for (int tries = 1; tries <= maxTries; tries++) {
      final exists = await _wallet.profileExists(username);

      if (!exists) {
        return username;
      }

      if (tries > maxTries) break;

      username = getRandomUsername();
      await delay(baseDelay * tries);
    }

    return null;
  }

  Future<void> giveProfileUsername() async {
    debugPrint('handleNewProfile');

    try {
      final username = await generateProfileUsername();
      if (username == null) {
        _state.setUsernameSuccess(username: '@anonymous');
        return;
      }

      _state.setUsernameSuccess(username: username);

      final address = _wallet.account.hexEip55;
      final alias = _wallet.alias ?? '';

      final dbProfile = await _accountBackupDBService.accounts
          .get(EthereumAddress.fromHex(address), alias);

      if (dbProfile == null) {
        debugPrint('dbProfile is null');
        return;
      }

      ProfileV1 profile = dbProfile.profile ??
          ProfileV1(
            account: address,
            username: username,
            name: dbProfile.name,
          );

      _profiles.isLoaded(
        profile.account,
        profile,
      );

      final exists = await _wallet.createAccount();
      if (!exists) {
        debugPrint('createAccount failed');
        return;
      }

      final url = await _wallet.setProfile(
        ProfileRequest.fromProfileV1(profile),
        image: await _photos.photoFromBundle('assets/icons/profile.jpg'),
        fileType: '.jpg',
      );
      if (url == null) {
        return;
      }

      final newProfile = await _wallet.getProfileFromUrl(url);
      if (newProfile == null) {
        return;
      }

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      _db.contacts.insert(
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
          alias: alias,
          address: EthereumAddress.fromHex(address),
          name: newProfile.name,
          username: newProfile.username,
          profile: newProfile,
          privateKey: null,
        ),
      );
    } catch (e, s) {
      debugPrint('giveProfileUsername error: $e, $s');
    }
  }
}
