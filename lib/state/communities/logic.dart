import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/app/db.dart';
import 'package:citizenwallet/state/communities/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class CommunitiesLogic {
  final CommunitiesState _state;
  final ConfigService config = ConfigService();
  final AppDBService _db = AppDBService();

  CommunitiesLogic(BuildContext context)
      : _state = context.read<CommunitiesState>();

  Future<void> silentFetchCommunities() async {
    try {
      _db.communities.refresh();

      final communities = await _db.communities.getAll();
      List<Config> communityConfigs =
          communities.map((c) => Config.fromJson(c.config)).toList();

      _state.upsertCommunities(communityConfigs);

      for (final communityConfig in communityConfigs) {
        if (communityConfig.community.hidden) {
          continue;
        }

        final isOnline =
            await config.isCommunityOnline(communityConfig.indexer.url);
        await _db.communities
            .updateOnlineStatus(communityConfig.community.alias, isOnline);

        _state.setCommunityOnline(communityConfig.community.alias, isOnline);
      }

      return;
    } catch (e) {
      //
    }
  }

  Future<void> fetchCommunities() async {
    try {
      _state.fetchCommunitiesRequest();

      final communities = await _db.communities.getAll();
      List<Config> communityConfigs =
          communities.map((c) => Config.fromJson(c.config)).toList();

      _state.fetchCommunitiesSuccess(communityConfigs);
      return;
    } catch (e) {
      //
    }

    _state.fetchCommunitiesFailure();
  }
}
