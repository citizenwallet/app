import 'package:citizenwallet/state/third_party/state.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ThirdPartyLogic {
  final ThirdPartyState _state;

  ThirdPartyLogic(BuildContext context)
      : _state = context.read<ThirdPartyState>();

  Future<void> openApp(String url) async {
    try {
      final uri = Uri.parse(url);

      launchUrl(uri, mode: LaunchMode.inAppWebView);
    } catch (e) {
      //
      print(e);
    }
  }
}
