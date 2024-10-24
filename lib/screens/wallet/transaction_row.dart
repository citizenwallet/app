import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/models/wallet.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/vouchers/state.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/profile/profile_circle.dart';
import 'package:citizenwallet/widgets/skeleton/pulsing_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class TransactionRow extends StatefulWidget {
  final CWTransaction transaction;
  final String? logo;
  final CWWallet wallet;
  final Map<String, ProfileItem> profiles;
  final Map<String, Voucher> vouchers;
  final void Function(String transactionId)? onTap;
  final void Function(String address)? onLoad;

  const TransactionRow({
    super.key,
    required this.transaction,
    this.logo,
    required this.wallet,
    required this.profiles,
    required this.vouchers,
    this.onTap,
    this.onLoad,
  });

  @override
  TransactionRowState createState() => TransactionRowState();
}

class TransactionRowState extends State<TransactionRow> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() {
    final transaction = widget.transaction;
    final wallet = widget.wallet;
    final isIncoming = transaction.isIncoming(wallet.account);
    final address = isIncoming ? transaction.from : transaction.to;

    if (widget.onLoad != null) widget.onLoad!(address);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final wallet = widget.wallet;
    final onTap = widget.onTap;

    final isSending = TransactionState.sending == transaction.state;
    final isIncoming = transaction.isIncoming(wallet.account);
    final address = isIncoming ? transaction.from : transaction.to;
    final addressEmpty = isEmptyAddress(address);
    final formattedAddress = addressEmpty ? '' : formatHexAddress(address);

    final profile = widget.profiles[address];
    final voucher = widget.vouchers[address];

    final date = transaction.date.toLocal();
    final isLessThanWeek = date.isAfter(
      DateTime.now().subtract(const Duration(days: 7)),
    );

    final formattedDate = isLessThanWeek
        ? timeago.format(date, locale: AppLocalizations.of(context)!.localeName)
        : DateFormat.yMMMd().format(date);

    return GestureDetector(
      onTap:
          transaction.isProcessing ? null : () => onTap?.call(transaction.id),
      child: AnimatedContainer(
        key: widget.key,
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        height: 80,
        decoration: BoxDecoration(
            border: Border(
          top: BorderSide(
            width: 1,
            color: Theme.of(context)
                .colors
                .subtleText
                .resolveFrom(context)
                .withOpacity(0.25),
          ),
        )),
        child: Stack(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    if (voucher != null)
                      ProfileCircle(
                        size: 50,
                        imageUrl: 'assets/icons/voucher.png',
                        backgroundColor: Theme.of(context).colors.transparent,
                      ),
                    if (voucher == null && addressEmpty)
                      CoinLogo(
                        size: 50,
                        logo: widget.logo,
                      ),
                    if (voucher == null && !addressEmpty)
                      ProfileCircle(
                        size: 50,
                        imageUrl: profile?.profile.imageMedium,
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profile != null && profile.loading
                          ? const PulsingContainer(
                              height: 24,
                              width: 100,
                            )
                          : RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: voucher != null
                                        ? isIncoming
                                            ? AppLocalizations.of(context)!
                                                .voucherRedeemed
                                            : AppLocalizations.of(context)!
                                                .voucherCreated
                                        : profile != null
                                            ? profile.profile.name
                                            : addressEmpty
                                                ? wallet.currencyName
                                                : AppLocalizations.of(context)!
                                                    .anonymous,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colors
                                          .text
                                          .resolveFrom(context),
                                    ),
                                  ),
                                  if (voucher == null)
                                    TextSpan(
                                      text: profile != null
                                          ? ' @${profile.profile.username}'
                                          : ' $formattedAddress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: Theme.of(context)
                                            .colors
                                            .subtleText
                                            .resolveFrom(context),
                                      ),
                                    ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      const SizedBox(height: 2),
                      SizedBox(
                        height: 20,
                        child: Text(
                          transaction.description.isNotEmpty
                              ? transaction.description
                              : addressEmpty
                                  ? AppLocalizations.of(context)!.minted
                                  : AppLocalizations.of(context)!.noDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context)
                                .colors
                                .subtleText
                                .resolveFrom(context),
                          ),
                        ),
                      ),
                      if (voucher != null && profile != null && profile.loading)
                        const SizedBox(height: 2),
                      if (transaction.isFailed && transaction.error != '')
                        SizedBox(
                          height: 20,
                          child: Text(
                            transaction.error,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Theme.of(context)
                                  .colors
                                  .danger
                                  .resolveFrom(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 80,
                  width: 120,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            isIncoming
                                ? '+ ${transaction.formattedAmount}'
                                : '- ${transaction.formattedAmount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: isIncoming
                                  ? Theme.of(context)
                                      .colors
                                      .primary
                                      .resolveFrom(context)
                                  : Theme.of(context)
                                      .colors
                                      .text
                                      .resolveFrom(context),
                            ),
                          ),
                          const SizedBox(width: 5),
                          CoinLogo(
                            size: 16,
                            logo: wallet.currencyLogo,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSending ? 'Pending' : formattedDate,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context)
                              .colors
                              .subtleText
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
