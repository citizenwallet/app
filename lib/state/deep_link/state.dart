import 'package:flutter/cupertino.dart';

class DeepLink {
  final String title;
  final String description;
  final String? content;
  final String action;
  final String? icon;
  final String? remoteIcon;

  const DeepLink({
    required this.title,
    required this.description,
    this.content,
    required this.action,
    this.icon,
    this.remoteIcon,
  });
}

const deepLinks = {
  'faucet-v1': DeepLink(
    title: 'Faucet',
    description: 'Claim some tokens',
    action: 'Claim',
    icon: 'assets/icons/faucet.svg',
  ),
  'community': DeepLink(
    title: 'Community',
    description: 'Join community',
    action: 'Join',
    icon: 'assets/icons/community.svg',
  ),
};

class DeepLinkState with ChangeNotifier {
  DeepLink? deepLink;

  DeepLinkState(String deepLinkName, {DeepLink? deepLink}) {
    this.deepLink = deepLink ?? deepLinks[deepLinkName];
  }

  bool loading = false;
  bool error = false;

  void request() {
    loading = true;
    error = false;
    notifyListeners();
  }

  void updateDeepLink(DeepLink deepLink) {
    this.deepLink = deepLink;
    notifyListeners();
  }

  void success() {
    loading = false;
    error = false;
    notifyListeners();
  }

  void fail() {
    loading = false;
    error = true;
    notifyListeners();
  }
}
