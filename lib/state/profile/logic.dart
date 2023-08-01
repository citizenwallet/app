import 'package:citizenwallet/services/photos/photos.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:citizenwallet/utils/uint8.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProfileLogic {
  late ProfileState _state;
  late ProfilesState _profiles;
  final PhotosService _photos = PhotosService();

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

  Future<void> selectPhoto() async {
    try {
      final result = await _photos.selectPhoto();

      if (result != null) _state.setEditImage(result.$1, result.$2);
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> checkUsername(String username) async {
    if (username == '') {
      _state.setUsernameError();
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
    try {
      _state.setProfileRequest();

      final profile =
          await _wallet.getProfile(account ?? _wallet.account.hexEip55);
      if (profile == null) {
        await delay(const Duration(milliseconds: 500));
        _state.setProfileNoChangeSuccess();
        return;
      }

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

      return;
    } catch (exception) {
      //
    }

    _state.setProfileError();
  }

  Future<void> loadViewProfile(String account) async {
    try {
      _state.viewProfileRequest();

      final profile = await _wallet.getProfile(account);
      if (profile == null) {
        await delay(const Duration(milliseconds: 500));
        _state.setViewProfileNoChangeSuccess();
        return;
      }

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

  Future<bool> save(ProfileV1 profile, Uint8List image, String ext) async {
    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text;
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final url = await _wallet.setProfile(
        ProfileRequest.fromProfileV1(profile),
        image: convertBytesToUint8List(image),
        fileType: ext,
      );
      if (url == null) {
        throw Exception('Failed to save profile');
      }

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

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.setProfileError();
    return false;
  }

  Future<bool> update(ProfileV1 profile) async {
    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text;
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;
      profile.image = _state.image;
      profile.imageMedium = _state.imageMedium;
      profile.imageSmall = _state.imageSmall;

      final existing = await _wallet.getProfile(profile.account);
      if (existing == null) {
        throw Exception('Failed to load profile');
      }

      if (existing == profile) {
        _state.setProfileNoChangeSuccess();
        return true;
      }

      final url = await _wallet.updateProfile(profile);
      if (url == null) {
        throw Exception('Failed to save profile');
      }

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

      _profiles.isLoaded(
        newProfile.account,
        newProfile,
      );

      return true;
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
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
}
