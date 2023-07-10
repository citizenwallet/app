import 'package:citizenwallet/services/sentry/sentry.dart';
import 'package:flutter_test/flutter_test.dart';

final List<String?> testWalletFragments = [
  null,
  '/wallet/0x000000',
  '/wallet/0x000000/transactions/0x000000',
  '',
  '/wallet/'
];

final List<String?> testWalletFragmentsScrubbed = [
  null,
  '/wallet/<redacted>',
  '/wallet/<redacted>/transactions/0x000000',
  '',
  '/wallet/'
];

void main() {
  test('scrubFragment', () {
    for (var i = 0; i < testWalletFragments.length; i++) {
      expect(scrubFragment(testWalletFragments[i]),
          testWalletFragmentsScrubbed[i]);
    }
  });
}
