import 'package:citizenwallet/services/wallet/contracts/profile.dart';
import 'package:citizenwallet/state/profiles/state.dart';

List<ProfileV1> selectProfileSuggestions(ProfilesState state) {
  if (!state.searchLoading &&
      state.searchedProfile == null &&
      state.searchResults.isEmpty) {
    return [];
  }

  Map<String, ProfileV1> profiles = {};

  if (state.searchedProfile != null) {
    profiles[state.searchedProfile!.username] = state.searchedProfile!;
  }

  for (final profile in state.searchResults) {
    profiles[profile.username] = profile;
  }

  return profiles.values.toList();
}
