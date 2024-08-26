import 'dart:async';

import 'package:flutter/foundation.dart';

// remove the sensitive part of the fragment
String? scrubFragment(String? fragment) {
  if (fragment == null) {
    return null;
  }

  // check if /wallet/ is in the fragment
  if (!fragment.contains('/wallet/')) {
    return fragment;
  }

  // split the fragment /wallet/
  final fragments = fragment.split('/');
  if (fragments.isEmpty) {
    return fragment;
  }

  // identify where the wallet is
  final walletIndex = fragments.indexOf('wallet');
  if (walletIndex == -1 || walletIndex + 1 >= fragments.length) {
    return fragment;
  }

  // redact the item after /wallet/
  final toRedact = fragments[walletIndex + 1];
  if (toRedact.isEmpty) {
    return fragment;
  }

  fragments[walletIndex + 1] = '<redacted>';

  return fragments.fold(
      '',
      (previousValue, element) =>
          element == '' ? previousValue : '$previousValue/$element');
}

// FutureOr<SentryEvent?> beforeSend(SentryEvent event, Hint? hint) async {
//   if (event.transaction == null || !kIsWeb) {
//     return event;
//   }

//   // scrub the fragment from the URL
//   event = event.copyWith(
//     transaction: scrubFragment(event.transaction),
//     request: event.request?.copyWith(
//       url: scrubFragment(event.request?.url),
//       fragment: scrubFragment(event.request?.fragment),
//     ),
//   ); // Don't send server names.
//   return event;
// }

// Future<void> initSentry(
//   bool debug,
//   String url,
//   FutureOr<void> Function()? appRunner,
// ) async {
//   await SentryFlutter.init(
//     (options) {
//       options.dsn = debug ? '' : url;
//       options.debug = debug;
//       // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
//       // We recommend adjusting this value in production.
//       options.tracesSampleRate = 1.0;
//       options.beforeSend = beforeSend;
//     },
//     appRunner: appRunner,
//   );
// }
