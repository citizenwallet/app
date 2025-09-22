import 'package:citizenwallet/services/accounts/accounts.dart';
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
import 'package:citizenwallet/state/wallet/state.dart';
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
  final AccountsServiceInterface _accountsService = getAccountsService();

  final AccountDBService _db = AccountDBService();
  late BuildContext _context;
  bool _pauseProfileCreation = false;

  ProfileLogic(BuildContext context) {
    _context = context;
    _state = context.read<ProfileState>();
    _profiles = context.read<ProfilesState>();
  }

  Config? get _config => _context.read<WalletState>().config;
  String? get _walletAccount => _context.read<WalletState>().wallet?.account;
  String? get _walletAlias => _context.read<WalletState>().wallet?.alias;

  Future<EthPrivateKey?> get _credentials async {
    final account = _walletAccount;
    final alias = _walletAlias;
    if (account == null || alias == null) return null;

    final dbAccount = await _accountsService.getAccount(account, alias, '');
    return dbAccount?.privateKey;
  }

  EthereumAddress? get _account {
    final account = _walletAccount;
    return account != null ? EthereumAddress.fromHex(account) : null;
  }

  Future<
      ({
        Config? config,
        EthPrivateKey? credentials,
        EthereumAddress? account
      })?> get _walletData async {
    final config = _config;
    final credentials = await _credentials;
    final account = _account;

    if (config == null || credentials == null || account == null) {
      return null;
    }

    return (config: config, credentials: credentials, account: account);
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

      final walletData = await _walletData;
      if (walletData == null) return;

      final community = await _appDBService.communities
          .get(walletData.config!.community.alias);

      if (community == null) {
        throw Exception('community not found');
      }

      Config communityConfig = Config.fromJson(community.config);

      final url = communityConfig.community.walletUrl(deepLinkURL);

      final compressedParams = compress(
          '?address=${walletData.account!.hexEip55}&alias=${communityConfig.community.alias}');

      _state.setProfileLinkSuccess('$url&receiveParams=$compressedParams');
      return;
    } catch (e) {
      // Add logging to help debug future issues
      debugPrint('Error loading profile link: $e');
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
    final walletData = await _walletData;
    if (walletData == null) {
      _state.setUsernameError();
      return;
    }

    if (username == '') {
      _state.setUsernameError();
    }

    if (username.length < 3) {
      _state.setUsernameError(
          message: 'Username must be at least 3 characters long.');
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      _state.setUsernameError(
          message:
              'Username can only contain letters, numbers, underscores, and hyphens.');
      return;
    }

    if (username.toLowerCase() == _state.username.toLowerCase()) {
      _state.setUsernameSuccess();
      return;
    }

    try {
      _state.setUsernameRequest();

      final exists =
          await profileExists(walletData.config!, username.toLowerCase());
      if (exists) {
        final existingProfile = await getProfileByUsername(
            walletData.config!, username.toLowerCase());
        if (existingProfile != null &&
            existingProfile.account == walletData.account!.hexEip55) {
          _state.setUsernameSuccess();
          return;
        }
        throw Exception('Already exists');
      }

      _state.setUsernameSuccess();
      return;
    } catch (exception) {
      debugPrint('Username check error: $exception');
      if (exception.toString().contains('Already exists')) {
        _state.setUsernameError(message: 'This username is already taken.');
      } else {
        _state.setUsernameError(
            message: 'Unable to check username availability.');
      }
    }
  }

  Future<void> loadProfile({String? account, bool online = false}) async {
    final walletData = await _walletData;
    if (walletData == null) return;

    final ethAccount = walletData.account!;
    final alias = walletData.config!.community.alias;
    final acc = account ?? ethAccount.hexEip55;

    resume();

    try {
      _state.setProfileRequest();

      final account =
          await _accountBackupDBService.accounts.get(ethAccount, alias, '');

      if (account != null && account.profile != null) {
        final profile = account.profile!;
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
        throw Exception('community is offline');
      }

      final profile = await getProfile(walletData.config!, acc);
      if (profile == null) {
        _state.setProfileNoChangeSuccess();

        if (_state.username.isEmpty) {
          giveProfileUsername();
        }

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

      // Get the existing account to preserve the account factory address
      final existingAccount =
          await _accountBackupDBService.accounts.get(ethAccount, alias, '');

      _accountBackupDBService.accounts.update(DBAccount(
        alias: alias,
        address: ethAccount,
        name: profile.name,
        username: profile.username,
        accountFactoryAddress: existingAccount?.accountFactoryAddress ?? '',
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

      final config = _config;
      if (config == null) return;

      final profile = await getProfile(config, account);
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

  /// Save a new profile with optional image
  Future<bool> save(ProfileV1 profile, Uint8List? image) async {
    final config = _config;
    final credentials = await _credentials;
    final account = _account;

    if (config == null || credentials == null || account == null) {
      return false;
    }

    try {
      _state.setProfileRequest();

      await delay(const Duration(milliseconds: 250));

      profile.username = _state.usernameController.value.text.toLowerCase();
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final exists = await createAccount(config, account, credentials);
      if (!exists) {
        throw Exception('Failed to create account');
      }

      _state.setProfileUploading();

      final Uint8List newImage = image != null
          ? convertBytesToUint8List(image)
          : await _photos.photoFromBundle('assets/icons/profile.jpg');

      final accountForFactory = await _accountBackupDBService.accounts
          .get(account, config.community.alias, '');

      final url = await setProfile(
        config,
        account,
        credentials,
        ProfileRequest.fromProfileV1(profile),
        image: newImage,
        fileType: '.jpg',
        accountFactoryAddress: accountForFactory?.accountFactoryAddress,
      );
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await getProfileFromUrl(config, url);
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

      final existingAccount = await _accountBackupDBService.accounts.get(
          EthereumAddress.fromHex(newProfile.account),
          config.community.alias,
          '');

      _accountBackupDBService.accounts.update(
        DBAccount(
          alias: config.community.alias,
          address: EthereumAddress.fromHex(newProfile.account),
          name: newProfile.name,
          username: newProfile.username,
          accountFactoryAddress: existingAccount?.accountFactoryAddress ?? '',
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

  /// Update an existing profile
  Future<bool> update(ProfileV1 profile) async {
    final config = _config;
    final credentials = await _credentials;
    final account = _account;

    if (config == null || credentials == null || account == null) {
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

      final existing = await getProfile(config, profile.account);
      if (existing == null) {
        throw Exception('Failed to load profile');
      }

      if (existing == profile) {
        _state.setProfileNoChangeSuccess();
        return true;
      }

      _state.setProfileUploading();

      final accountForFactory = await _accountBackupDBService.accounts
          .get(account, config.community.alias, '');

      if (accountForFactory == null) {}

      final factoryAddress = accountForFactory?.accountFactoryAddress;

      final url = await updateProfile(
        config,
        account,
        credentials,
        profile,
        accountFactoryAddress: factoryAddress,
      );
      if (url == null) {
        throw Exception('Failed to save profile');
      }

      _state.setProfileFetching();

      final newProfile = await getProfileFromUrl(config, url);
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

      final existingAccount = await _accountBackupDBService.accounts.get(
          EthereumAddress.fromHex(newProfile.account),
          config.community.alias,
          '');

      _accountBackupDBService.accounts.update(
        DBAccount(
          alias: config.community.alias,
          address: EthereumAddress.fromHex(newProfile.account),
          name: newProfile.name,
          username: newProfile.username,
          accountFactoryAddress: existingAccount?.accountFactoryAddress ?? '',
          privateKey: null,
          profile: newProfile,
        ),
      );

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint('ProfileLogic.update() - Error during profile update: $e');
      debugPrint('Stack trace: $stackTrace');
    }

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
    final walletData = await _walletData;
    if (walletData == null) return null;

    String username = await getRandomUsername();
    _state.setUsernameSuccess(username: username);

    const maxTries = 3;
    const baseDelay = Duration(milliseconds: 100);

    for (int tries = 1; tries <= maxTries; tries++) {
      final exists = await profileExists(walletData.config!, username);

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

    final walletData = await _walletData;
    if (walletData == null) return;

    try {
      final username = await generateProfileUsername();
      if (username == null) {
        _state.setUsernameSuccess(username: '@anonymous');
        return;
      }

      final address = walletData.account!.hexEip55;
      final alias = walletData.config!.community.alias;

      final account = await _accountBackupDBService.accounts
          .get(EthereumAddress.fromHex(address), alias, '');

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

      if (_pauseProfileCreation) {
        return;
      }

      final exists = await createAccount(
          walletData.config!, walletData.account!, walletData.credentials!);
      if (!exists) {
        throw Exception('Failed to create account');
      }

      if (_pauseProfileCreation) {
        return;
      }

      final url = await setProfile(
        walletData.config!,
        walletData.account!,
        walletData.credentials!,
        ProfileRequest.fromProfileV1(profile),
        image: await _photos.photoFromBundle('assets/icons/profile.jpg'),
        fileType: '.jpg',
        accountFactoryAddress: account.accountFactoryAddress,
      );
      if (url == null) {
        throw Exception('Failed to create profile url');
      }

      if (_pauseProfileCreation) {
        return;
      }

      final newProfile = await getProfileFromUrl(walletData.config!, url);
      if (newProfile == null) {
        throw Exception('Failed to get profile from url $url');
      }

      _state.setUsernameSuccess(username: newProfile.username);
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
          accountFactoryAddress: account.accountFactoryAddress,
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
