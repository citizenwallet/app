import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/loaders/progress_circle.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChargeProgress extends StatefulWidget {
  final String? from;

  const ChargeProgress({super.key, this.from});

  @override
  State<ChargeProgress> createState() => _ChargeProgressState();
}

class _ChargeProgressState extends State<ChargeProgress> {
  TransactionState _previousState = TransactionState.sending;
  bool _isClosing = false;

  void handleDone(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    final navigator = GoRouter.of(context);

    navigator.pop(true);
  }

  void handleRetry(BuildContext context) {
    final navigator = GoRouter.of(context);

    navigator.pop();
  }

  void handleStartCloseScreenTimer(BuildContext context) {
    if (_isClosing) {
      return;
    }

    _isClosing = true;

    Future.delayed(const Duration(seconds: 5), () {
      if (!context.mounted) {
        return;
      }

      handleDone(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final wallet = context.select((WalletState state) => state.wallet);

    if (wallet == null) {
      return const SizedBox();
    }

    final inProgressTransaction =
        context.select((WalletState state) => state.inProgressTransaction);

    if (inProgressTransaction == null) {
      return const SizedBox();
    }

    final inProgressTransactionError = context.select(
      (WalletState state) => state.inProgressTransactionError,
    );

    if (inProgressTransaction.state == TransactionState.pending &&
        _previousState == TransactionState.sending) {
      // start a timer to close the screen after a few seconds
      handleStartCloseScreenTimer(context);
    }

    _previousState = inProgressTransaction.state;

    final isSending = inProgressTransaction.state == TransactionState.sending;

    final formattedAmount = inProgressTransaction.amount;

    final selectedProfile =
        context.select((ProfilesState state) => state.selectedProfile);

    final date = DateFormat.yMMMd().add_Hm().format(inProgressTransaction.date);

    final statusMessage = inProgressTransactionError
        ? AppLocalizations.of(context)!.chargeFailed(wallet.symbol)
        : isSending
            ? AppLocalizations.of(context)!.charging
            : '${AppLocalizations.of(context)!.charged}! 🎉';

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor:
            Theme.of(context).colors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum:
              const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              const SizedBox(height: 60),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ProgressCircle(
                                progress: inProgressTransactionError
                                    ? 0
                                    : switch (inProgressTransaction.state) {
                                        TransactionState.sending => 0.5,
                                        TransactionState.pending => 1,
                                        TransactionState.success => 1,
                                        _ => 0,
                                      },
                                size: 100,
                                color: Theme.of(context)
                                    .colors
                                    .primary
                                    .resolveFrom(context),
                                trackColor: inProgressTransactionError
                                    ? Theme.of(context)
                                        .colors
                                        .danger
                                        .resolveFrom(context)
                                        .withOpacity(0.25)
                                    : null,
                                successChild: Icon(
                                  CupertinoIcons.checkmark,
                                  size: 60,
                                  color: Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            statusMessage,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colors
                                  .text
                                  .resolveFrom(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                formattedAmount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colors
                                      .text
                                      .resolveFrom(context),
                                ),
                              ),
                              const SizedBox(width: 20),
                              CoinLogo(
                                size: 60,
                                logo: wallet.currencyLogo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 40,
                                width: 40,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      child: Icon(
                                        CupertinoIcons.chevron_up,
                                        color: Theme.of(context)
                                            .colors
                                            .subtleSolid
                                            .resolveFrom(context),
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      child: Icon(
                                        CupertinoIcons.chevron_up,
                                        color: Theme.of(context)
                                            .colors
                                            .subtleSolid
                                            .resolveFrom(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ProfileCircle(
                                imageUrl: selectedProfile?.imageSmall,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedProfile?.name ??
                                    formatHexAddress(widget.from ?? ''),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colors
                                      .text
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                          if (!isSending && !inProgressTransactionError)
                            const SizedBox(height: 20),
                          if (!isSending && !inProgressTransactionError)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.time,
                                  color: Theme.of(context)
                                      .colors
                                      .subtleSolid
                                      .resolveFrom(context),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colors
                                        .subtleSolid
                                        .resolveFrom(context),
                                    fontWeight: FontWeight.normal,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSending && !inProgressTransactionError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Button(
                      text: AppLocalizations.of(context)!.dismiss,
                      labelColor:
                          Theme.of(context).colors.white.resolveFrom(context),
                      onPressed: () => handleDone(context),
                      minWidth: 200,
                      maxWidth: width - 60,
                    ),
                  ],
                ),
              if (inProgressTransactionError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Button(
                      text: AppLocalizations.of(context)!.retry,
                      labelColor:
                          Theme.of(context).colors.white.resolveFrom(context),
                      onPressed: () => handleRetry(context),
                      minWidth: 200,
                      maxWidth: width - 60,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
