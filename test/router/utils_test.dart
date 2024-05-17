import 'package:citizenwallet/router/utils.dart';
import 'package:test/test.dart';

void main() {
  group('DeepLink URI Parsing', () {
    const faucetUri =
        'https://app.citizenwallet.xyz/#/?dl=faucet-v1&faucet-v1=alias%3Dwallet.wolugo.be%26address%3D0x6a5c6c77789115315d162B6659e666C52d30717F';
    const expectedAlias = 'wallet.wolugo.be';
    const expectedDeepLinkName = 'faucet-v1';
    const expectedDeepLinkParams =
        'alias%3Dwallet.wolugo.be%26address%3D0x6a5c6c77789115315d162B6659e666C52d30717F';
    test('parse alias from faucet uri', () {
      final alias = aliasFromDeepLinkUri(faucetUri);

      expect(alias, expectedAlias);
    });

    test('parse deep link from faucet uri', () {
      final (_, deepLinkContent) = deepLinkContentFromUri(faucetUri);

      expect(deepLinkContent, expectedDeepLinkName);
    });

    test('parse deep link params from faucet uri', () {
      final (_, _, deepLinkParams) = deepLinkParamsFromUri(faucetUri);

      expect(deepLinkParams, expectedDeepLinkParams);
    });
  });

  group('Receive URI parsing', () {
    const receiveUri =
        'https://zinne.citizenwallet.xyz/#/?alias=zinne&receiveParams=H4sIAOwZHmYA_w3MWQqAIBQAwNv4GSqKvQ-JQLvHcyvBBbIgOn3NAWbBEM44hqYPY9YI7hhIOQu1JaFUQgvWe1jBBDVLD07wQLBkHPrNrUWCtd_t0myilNT_wT3qI5bSP9IF7TdZAAAA';
    const expectedAlias = 'zinne';
    const expectedReceiveParams =
        'H4sIAOwZHmYA_w3MWQqAIBQAwNv4GSqKvQ-JQLvHcyvBBbIgOn3NAWbBEM44hqYPY9YI7hhIOQu1JaFUQgvWe1jBBDVLD07wQLBkHPrNrUWCtd_t0myilNT_wT3qI5bSP9IF7TdZAAAA';

    test('parse alias from receive uri', () {
      final alias = aliasFromReceiveUri(receiveUri);

      expect(alias, expectedAlias);
    });

    test('parse receive params from uri', () {
      final (_, receiveParams, _) = deepLinkParamsFromUri(receiveUri);

      expect(receiveParams, expectedReceiveParams);
    });
  });

  group('Voucher URI parsing', () {
    const voucherURI =
        'https://zinne.citizenwallet.xyz/#/?alias=zinne&voucher=F4sIAD4XHmYA_w3JwQ3AMAgDwIkqOSgQPA5J8Aidv73vvfZEzItl2bVDdVnz8CBbjjk2dvWZ_eWDTV5PdACSmJSf9QGxLV9mQwAAAB==&params=4sIAD4XHmOA_w3LvQ7CIBAA4Ffp1Jsj78rAQFJPXDo6uB0HxCYKCbaJ8en12z967vT23721NvModPThxQcgrlomcMYsGi9VI1aKLjK74NaMi2GXtMwzMfezHf8iqjJaAlpgg2HBlFIwCqlIEFZYxQFIaMhzo1fxt37yo4yp9jHBdL9uW_wBhXpT_IoAAAA=&alias=zinne';
    const expectedAlias = 'zinne';
    const expectedVoucher =
        'F4sIAD4XHmYA_w3JwQ3AMAgDwIkqOSgQPA5J8Aidv73vvfZEzItl2bVDdVnz8CBbjjk2dvWZ_eWDTV5PdACSmJSf9QGxLV9mQwAAAB==';
    const expectedVoucherParams =
        '4sIAD4XHmOA_w3LvQ7CIBAA4Ffp1Jsj78rAQFJPXDo6uB0HxCYKCbaJ8en12z967vT23721NvModPThxQcgrlomcMYsGi9VI1aKLjK74NaMi2GXtMwzMfezHf8iqjJaAlpgg2HBlFIwCqlIEFZYxQFIaMhzo1fxt37yo4yp9jHBdL9uW_wBhXpT_IoAAAA=';

    test('parse alias from voucher uri', () {
      final alias = aliasFromUri(voucherURI);

      expect(alias, expectedAlias);
    });

    test('parse voucher from voucher uri', () {
      final (voucher, _) = deepLinkContentFromUri(voucherURI);

      expect(voucher, expectedVoucher);
    });

    test('parse voucher params from voucher uri', () {
      final (voucherParams, _, _) = deepLinkParamsFromUri(voucherURI);

      expect(voucherParams, expectedVoucherParams);
    });
  });
}
