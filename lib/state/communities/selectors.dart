import 'package:citizenwallet/services/config/config.dart';
import 'package:citizenwallet/state/communities/state.dart';

List<Config> selectVisibleCommunities(CommunitiesState state) =>
    state.communities
        .where((Config config) => !config.community.hidden)
        .toList();

Map<String, CommunityConfig> selectMappedCommunityConfigs(
        CommunitiesState state) =>
    state.communities.fold({},
        (Map<String, CommunityConfig> map, Config config) {
      map[config.community.alias] = config.community;
      return map;
    });
