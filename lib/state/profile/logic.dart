import 'package:citizenwallet/services/photos/photos.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet2.dart';
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

  final WalletService2 _wallet = WalletService2();

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

  Future<void> loadProfile() async {
    try {
      _state.setProfileRequest();

      final profile = await _wallet.getProfile(_wallet.account.hex);
      if (profile == null) {
        await delay(const Duration(milliseconds: 500));
        throw Exception('Failed to load profile');
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

  Future<void> save(ProfileV1 profile, Uint8List image, String ext) async {
    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text;
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final success = await _wallet.setProfile(
        ProfileRequest.fromProfileV1(profile),
        image: convertBytesToUint8List(image),
        fileType: ext,
      );
      if (!success) {
        throw Exception('Failed to save profile');
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
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.setProfileError();
  }

  Future<void> update(ProfileV1 profile) async {
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

      if (existing != profile) {
        final success = await _wallet.updateProfile(profile);
        if (!success) {
          throw Exception('Failed to save profile');
        }
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
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.setProfileError();
  }

  void updateNameErrorState(String name) {
    _state.setNameError(name.isEmpty);
  }

  void updateDescriptionText(String desc) {
    _state.setDescriptionText(desc);
  }
}
