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
  Map<String, ProfileV1> usernames = {};

  ProfileV1? searchedProfile;
  List<ProfileV1> searchResults = [];
  bool searchLoading = false;
  bool searchError = false;

  ProfileV1? selectedProfile;

  List<ProfileV1> profileList = [];
  bool profileListLoading = true;
  bool profileListError = false;

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
    usernames[profile.username] = profile;
    notifyListeners();
  }

  void isError(String address) {
    if (profiles[address] == null) {
      return;
    }

    profiles.remove(address);

    notifyListeners();
  }

  void clearSearch({bool notify = true}) {
    searchedProfile = null;
    searchResults = [];
    searchLoading = false;
    searchError = false;

    selectedProfile = null;
    if (notify) notifyListeners();
  }

  void clearProfiles() {
    profileList = [];
    profileListLoading = true;
    profileListError = false;
  }

  void isSearching() {
    searchLoading = true;
    searchError = false;
    notifyListeners();
  }

  void isSearchingSuccess(ProfileV1? profile, List<ProfileV1> results) {
    searchResults = results;
    searchedProfile = profile;
    searchLoading = false;
    searchError = false;
    notifyListeners();
  }

  void isSearchingError() {
    searchedProfile = null;
    searchLoading = false;
    searchError = true;
    notifyListeners();
  }

  void isSelected(ProfileV1? profile) {
    if (profile != null) {
      selectedProfile = profile.copyWith();
      notifyListeners();
      return;
    }

    if (searchedProfile == null) {
      return;
    }

    selectedProfile = searchedProfile!.copyWith();
    searchedProfile = null;

    notifyListeners();
  }

  void isDeSelected() {
    if (selectedProfile == null) {
      return;
    }

    searchedProfile = selectedProfile!.copyWith();
    selectedProfile = null;
    notifyListeners();
  }

  void profileListRequest() {
    profileListLoading = true;
    profileListError = false;
    notifyListeners();
  }

  void profileListSuccess(List<ProfileV1> profiles) {
    profileList = profiles;
    profileListLoading = false;
    profileListError = false;
    notifyListeners();
  }

  void profileListFail() {
    profileList = [];
    profileListLoading = false;
    profileListError = true;
    notifyListeners();
  }

  ProfileV1? getLocalUsername(String address) {
    return usernames[address];
  }

  bool exists(String address) {
    return profiles[address] != null && profiles[address]!.error == false;
  }
}
