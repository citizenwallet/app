import 'package:citizenwallet/services/photos/photos.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet2.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/utils/delay.dart';
import 'package:flutter/cupertino.dart';
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

  void startEdit() {
    _state.startEdit();
  }

  Future<void> selectPhoto() async {
    try {
      final photo = await _photos.selectPhoto();

      if (photo != null) _state.setEditImage(photo);
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

  Future<void> save(ProfileV1 profile) async {
    try {
      _state.setProfileRequest();

      profile.username = _state.usernameController.value.text;
      profile.name = _state.nameController.value.text;
      profile.description = _state.descriptionController.value.text;

      final (photo, extension) = await _photos.photoToData(profile.image);
      final success = await _wallet.setProfile(
        ProfileRequest.fromProfileV1(profile),
        image: photo,
        fileType: extension,
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

  void updateNameErrorState(String name) {
    _state.setNameError(name.isEmpty);
  }

  void updateDescriptionText(String desc) {
    _state.setDescriptionText(desc);
  }
}
