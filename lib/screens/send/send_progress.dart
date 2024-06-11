import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/loaders/progress_circle.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SendProgress extends StatefulWidget {
  final String? to;

  const SendProgress({super.key, this.to});

  @override
  State<SendProgress> createState() => _SendProgressState();
}

class _SendProgressState extends State<SendProgress> {
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

    final formattedAmount = formatAmount(
      double.parse(fromDoubleUnit(
        inProgressTransaction.amount,
        decimals: wallet.decimalDigits,
      )),
      decimalDigits: 2,
    );

    final selectedProfile =
        context.select((ProfilesState state) => state.selectedProfile);

    final date = DateFormat.yMMMd().add_Hm().format(inProgressTransaction.date);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
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
                                progress: switch (inProgressTransaction.state) {
                                  TransactionState.sending => 0.5,
                                  TransactionState.pending => 1,
                                  TransactionState.success => 1,
                                  _ => 0,
                                },
                                size: 100,
                                color: ThemeColors.primary.resolveFrom(context),
                                trackColor: inProgressTransactionError
                                    ? ThemeColors.danger
                                        .resolveFrom(context)
                                        .withOpacity(0.25)
                                    : null,
                                successChild: Icon(
                                  CupertinoIcons.checkmark,
                                  size: 60,
                                  color:
                                      ThemeColors.success.resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isSending
                                ? AppLocalizations.of(context)!.sending
                                : !inProgressTransactionError
                                    ? '${AppLocalizations.of(context)!.sent}! 🎉'
                                    : AppLocalizations.of(context)!
                                        .failedSend(wallet.symbol),
                            style: TextStyle(
                              color: ThemeColors.text.resolveFrom(context),
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CoinLogo(
                                size: 60,
                                logo: wallet.currencyLogo,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                formattedAmount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.text.resolveFrom(context),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  0,
                                  0,
                                  0,
                                ),
                                child: Text(
                                  wallet.symbol,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Row(
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
                                        CupertinoIcons.chevron_down,
                                      ),
                                    ),
                                    Positioned(
                                      top: 10,
                                      child: Icon(
                                        CupertinoIcons.chevron_down,
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
                                    formatHexAddress(widget.to ?? ''),
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
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
                                  color: ThemeColors.subtleSolid
                                      .resolveFrom(context),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  date,
                                  style: TextStyle(
                                    color: ThemeColors.subtleSolid
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
                      labelColor: ThemeColors.white.resolveFrom(context),
                      onPressed: () => handleDone(context),
                      minWidth: 200,
                      maxWidth: width - 60,
                    ),
                  ],
                ),
              if (!isSending && inProgressTransactionError)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Button(
                      text: AppLocalizations.of(context)!.retry,
                      labelColor: ThemeColors.white.resolveFrom(context),
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
