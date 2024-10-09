import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/services/db/app/communities.dart';
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
      final communities = await _db.communities.getAll();
      List<Config> communityConfigs =
          communities.map((c) => Config.fromJson(c.config)).toList();
      _state.fetchCommunitiesSuccess(communityConfigs);

      // Grouped operations for fetching and upserting communities
      (() async {
        final List<Config> communities =
            await config.getCommunitiesFromRemote();

        _state.upsertCommunities(communityConfigs);

        await _db.communities
            .upsert(communities.map((c) => DBCommunity.fromConfig(c)).toList());
      })();

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

  void fetchCommunitiesFromRemote() async {
    try {
      final List<Config> communities = await config.getCommunitiesFromRemote();
      await _db.communities
          .upsert(communities.map((c) => DBCommunity.fromConfig(c)).toList());
      return;
    } catch (e) {
      //
    }
  }

  Future<bool> isAliasFromDeeplinkExist(String alias) async {
    bool communityExists = await _db.communities.exists(alias);

    for (int attempt = 0; attempt < 2 && !communityExists; attempt++) {
      final List<Config> communities = await config.getCommunitiesFromRemote();

      for (final community in communities) {
        final isOnline = await config.isCommunityOnline(community.indexer.url);

        await _db.communities.upsert([DBCommunity.fromConfig(community)]);
        await _db.communities
            .updateOnlineStatus(community.community.alias, isOnline);
      }

      // Check again if the community exists after the update
      communityExists = await _db.communities.exists(alias);
    }

    return communityExists;
  }

  Future<void> initializeAppDB() async {
    try {
      await _db.init('app');
    } catch (e) {
      //
    }
  }
}
