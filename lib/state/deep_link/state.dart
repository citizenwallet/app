import 'package:flutter/cupertino.dart';

class DeepLink {
  final String title;
  final String description;
  final String action;
  final String? icon;

  const DeepLink({
    required this.title,
    required this.description,
    required this.action,
    this.icon,
  });
}

const deepLinks = {
  'faucet-v1': DeepLink(
    title: 'Faucet',
    description: 'Claim some tokens',
    action: 'Claim',
    icon: 'assets/icons/faucet.svg',
  ),
};

class DeepLinkState with ChangeNotifier {
  DeepLink? deepLink;

  DeepLinkState(String deepLinkName) {
    deepLink = deepLinks[deepLinkName];
  }

  bool loading = false;
  bool error = false;

  void request() {
    loading = true;
    error = false;
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

  BigInt faucetAmount = BigInt.zero;

  void setFaucetAmount(BigInt amount) {
    faucetAmount = amount;
    notifyListeners();
  }
}
