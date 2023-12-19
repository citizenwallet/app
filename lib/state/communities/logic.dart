import 'package:citizenwallet/services/config/service.dart';
import 'package:citizenwallet/state/communities/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class CommunitiesLogic {
  final CommunitiesState _state;
  final ConfigService config = ConfigService();

  CommunitiesLogic(BuildContext context)
      : _state = context.read<CommunitiesState>();

  Future<void> silentFetchCommunities() async {
    try {
      final communities = await config.getConfigs();

      _state.fetchCommunitiesSuccess(communities);
      return;
    } catch (e) {
      //
    }
  }

  Future<void> fetchCommunities() async {
    try {
      _state.fetchCommunitiesRequest();

      final communities = await config.getConfigs();

      _state.fetchCommunitiesSuccess(communities);
      return;
    } catch (e) {
      //
    }

    _state.fetchCommunitiesFailure();
  }
}
