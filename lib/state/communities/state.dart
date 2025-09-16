import 'package:citizenwallet/services/config/config.dart';
import 'package:flutter/cupertino.dart';

class CommunitiesState with ChangeNotifier {
  List<Config> communities = [];

  bool loading = false;
  bool error = false;

  void fetchCommunitiesRequest() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void fetchCommunitiesSuccess(List<Config> communities) {
    this.communities = [...communities];
    loading = false;
    error = false;
    notifyListeners();
  }

  void upsertCommunities(List<Config> incomingCommunities) {
    for (final incomingCommunity in incomingCommunities) {
      final existingIndex = communities.indexWhere((community) =>
          community.community.alias == incomingCommunity.community.alias);

      if (existingIndex != -1) {
        // Update existing community
        incomingCommunity.online = communities[existingIndex].online;
        communities[existingIndex] = incomingCommunity;
      } else {
        // Add new community
        communities.add(incomingCommunity);
      }
    }

    communities = List<Config>.from(communities);
    notifyListeners();
  }

  void fetchCommunitiesFailure() {
    loading = false;
    error = true;
    notifyListeners();
  }

  void setCommunityOnline(String alias, bool online) {
    final community =
        communities.firstWhere((element) => element.community.alias == alias);
    community.online = online;
    notifyListeners();
  }
}
