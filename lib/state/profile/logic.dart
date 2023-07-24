import 'package:citizenwallet/services/photos/photos.dart';
import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/services/wallet/wallet2.dart';
import 'package:citizenwallet/state/profile/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProfileLogic {
  late ProfileState _state;
  final PhotosService _photos = PhotosService();

  final WalletService2 _wallet = WalletService2();

  ProfileLogic(BuildContext context) {
    _state = context.read<ProfileState>();
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

  Future<void> save(ProfileV1 profile) async {
    try {
      _state.setProfileRequest();

      _state.setProfileSuccess(
        address: profile.address,
        username: profile.username,
        name: profile.name,
        description: profile.description,
        image: profile.image,
        imageMedium: profile.imageMedium,
        imageSmall: profile.imageSmall,
      );
    } catch (exception, stackTrace) {
      Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
    }

    _state.setProfileError();
  }
}
