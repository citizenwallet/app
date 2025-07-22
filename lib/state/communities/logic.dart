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
      debugPrint('Error fetching communities: $e');
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
      final communities = await _db.communities.getAll();
      for (final community in communities) {
        final config = Config.fromJson(community.config);
        if (config.community.hidden) {
          continue;
        }

        final token = config.getPrimaryToken();
        final chain = config.chains[token.chainId.toString()];

        if (chain != null) {
          final isOnline = await this.config.isCommunityOnline(chain.node.url);
          await _db.communities
              .updateOnlineStatus(config.community.alias, isOnline);
        }
      }
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

    return false;
  }

  Future<void> initializeAppDB() async {
    try {
      await _db.init('app');
    } catch (e) {
      //
    }
  }

  Future<void> fetchAndUpdateSingleCommunity(String alias) async {
    try {
      final community = await _db.communities.get(alias);
      if (community == null) {
        return;
      }

      final config = Config.fromJson(community.config);
      final remoteConfig =
          await this.config.getSingleCommunityConfig(config.configLocation);

      if (remoteConfig != null) {
        await _db.communities.upsert([DBCommunity.fromConfig(remoteConfig)]);

        final existingIndex = _state.communities.indexWhere(
          (c) => c.community.alias == alias,
        );

        if (existingIndex != -1) {
          remoteConfig.online = _state.communities[existingIndex].online;
          _state.communities[existingIndex] = remoteConfig;
          _state.notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching single community: $e');
    }
  }
}
