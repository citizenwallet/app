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

  Future<void> silentFetch() async {
    if (config.singleCommunityMode) {
      await _silentFetchSingle();
    } else {
      await _silentFetchAll();
    }
  }

  Future<void> _silentFetchAll() async {
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

        final token = communityConfig.getPrimaryToken();
        final chain = communityConfig.chains[token.chainId.toString()];

        if (chain == null) {
          _state.setCommunityOnline(communityConfig.community.alias, false);
          _db.communities
              .updateOnlineStatus(communityConfig.community.alias, false);
          continue;
        }

        config.isCommunityOnline(chain.node.url).then((isOnline) {
          _state.setCommunityOnline(communityConfig.community.alias, isOnline);
          _db.communities
              .updateOnlineStatus(communityConfig.community.alias, isOnline);
        });
      }

      return;
    } catch (e) {
      //
    }
  }

  Future<void> _silentFetchSingle() async {
    try {
      final communities = await _db.communities.getAll();
      List<Config> communityConfigs =
          communities.map((c) => Config.fromJson(c.config)).toList();
      _state.fetchCommunitiesSuccess(communityConfigs);

      if (communityConfigs.isEmpty) {
        return;
      }

      final first = communityConfigs.first;

      if (first.community.hidden) {
        return;
      }

      final token = first.getPrimaryToken();
      final chain = first.chains[token.chainId.toString()];

      final isOnline = await config.isCommunityOnline(chain!.node.url);
      _state.setCommunityOnline(first.community.alias, isOnline);
      await _db.communities.updateOnlineStatus(first.community.alias, isOnline);

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

  void fetchFromRemote() async {
    if (config.singleCommunityMode) {
      _fetchSingleCommunityFromRemote();
    } else {
      _fetchAllCommunitiesFromRemote();
    }
  }

  void _fetchAllCommunitiesFromRemote() async {
    try {
      final List<Config> communities = await config.getCommunitiesFromRemote();
      await _db.communities
          .upsert(communities.map((c) => DBCommunity.fromConfig(c)).toList());
      return;
    } catch (e) {
      //
    }
  }

  void _fetchSingleCommunityFromRemote() async {
    try {
      final communities = await _db.communities.getAll();
      List<Config> communityConfigs =
          communities.map((c) => Config.fromJson(c.config)).toList();

      if (communityConfigs.isEmpty) {
        return;
      }

      final first = communityConfigs.first;

      final remoteCommunity =
          await config.getRemoteConfig(first.configLocation);

      if (remoteCommunity == null) {
        return;
      }

      await _db.communities.upsert([DBCommunity.fromConfig(remoteCommunity)]);
      return;
    } catch (e) {
      //
    }
  }

  Future<bool> isAliasFromDeeplinkExist(String alias) async {
    bool communityExists = await _db.communities.exists(alias);
    if (communityExists) {
      return true;
    }

    for (int attempt = 0; attempt < 2; attempt++) {
      final List<Config> communities = await config.getCommunitiesFromRemote();

      for (final community in communities) {
        if (community.community.alias != alias) {
          continue;
        }

        final token = community.getPrimaryToken();
        final chain = community.chains[token.chainId.toString()];

        final isOnline = await config.isCommunityOnline(chain!.node.url);

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
