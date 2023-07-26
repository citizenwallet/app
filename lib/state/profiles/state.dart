import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:flutter/cupertino.dart';

class ProfileItem {
  bool loading = false;
  bool error = false;
  ProfileV1 profile;

  ProfileItem(this.profile);

  ProfileItem.empty() : profile = ProfileV1();

  void isLoading() {
    loading = true;
    error = false;
  }

  void isLoaded(ProfileV1 profile) {
    loading = false;
    error = false;
    this.profile = profile;
  }

  void isError() {
    loading = false;
    error = true;
  }
}

class ProfilesState with ChangeNotifier {
  Map<String, ProfileItem> profiles = {};

  void isLoading(String address) {
    if (profiles[address] == null) {
      profiles[address] = ProfileItem.empty();
    }

    profiles[address]!.isLoading();
    notifyListeners();
  }

  void isLoaded(String address, ProfileV1 profile) {
    profiles[address] = ProfileItem(profile);
    profiles[address]!.isLoaded(profile);
    notifyListeners();
  }

  void isError(String address) {
    if (profiles[address] == null) {
      return;
    }

    profiles.remove(address);

    notifyListeners();
  }

  bool exists(String address) {
    return profiles[address] != null && profiles[address]!.error == false;
  }
}
