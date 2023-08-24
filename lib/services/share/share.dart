import 'package:flutter/cupertino.dart';
import 'package:share_plus/share_plus.dart';

class SharingService {
  static final SharingService _instance = SharingService._internal();

  factory SharingService() => _instance;

  SharingService._internal();

  Future<void> shareVoucher(
    String amount, {
    required String link,
    required String symbol,
    required Rect sharePositionOrigin,
  }) async {
    final shareText =
        'Here is a voucher 🎁 for $amount $symbol:\n\n$link\n\nGenerated using Citizen Wallet 📱';

    return Share.share(
      shareText,
      subject: 'Voucher for $amount $symbol',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> shareWallet(String link, Rect sharePositionOrigin) {
    final shareText = '''
Hey there 👋, 

This is the backup link to your Citizen Wallet 📱:
$link

By following this link, you can gain access to this wallet.

Remember to only share this link with people you trust. Anyone with this link can access your wallet and send transactions on your behalf.

Regards,

The Citizen Wallet Team
    ''';

    return Share.share(
      shareText,
      subject: 'My Wallet Backup Link',
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}
