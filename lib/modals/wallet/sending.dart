import 'dart:async';

import 'package:citizenwallet/models/transaction.dart';
import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/profiles/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/blurry_child.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/coin_logo.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/loaders/progress_bar.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:citizenwallet/widgets/wallet/coin_spinner.dart';
import 'package:citizenwallet/widgets/wallet/transaction_state_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class SendingModal extends StatefulWidget {
  final WalletLogic logic;

  const SendingModal({
    super.key,
    required this.logic,
  });

  @override
  State<SendingModal> createState() => _SendingModalState();
}

class _SendingModalState extends State<SendingModal> {
  Timer? _timer;

  late ProfilesLogic _profileLogic;

  @override
  void initState() {
    super.initState();

    _profileLogic = ProfilesLogic(context);
  }

  @override
  void dispose() {
    widget.logic.clearInProgressTransaction();
    _timer?.cancel();
    super.dispose();
  }

  void handleDismissLater() async {
    _timer ??= Timer(const Duration(seconds: 10), () {
      handleDismiss(context);
    });
  }

  void handleLoadProfile(String address) {
    _profileLogic.loadProfile(address);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final wallet = context.select((WalletState state) => state.wallet);

    final inProgressTransaction =
        context.select((WalletState state) => state.inProgressTransaction);
    final inProgressTransactionLoading = context
        .select((WalletState state) => state.inProgressTransactionLoading);
    final inProgressTransactionError =
        context.select((WalletState state) => state.inProgressTransactionError);

    if (wallet == null || inProgressTransaction == null) {
      return const SizedBox();
    }

    if (inProgressTransaction.state == TransactionState.pending) {
      handleDismissLater();
    }

    final profiles = context.select((ProfilesState state) => state.profiles);
    final profileItem = profiles[inProgressTransaction.to];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.uiBackgroundAlt.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 20),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Header(
                  title: inProgressTransactionLoading ? 'Sending' : 'Sent',
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: ListView(
                        controller: ModalScrollController.of(context),
                        physics: const ScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        scrollDirection: Axis.vertical,
                        children: inProgressTransactionError
                            ? [
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: CoinLogo(
                                      size: 160,
                                      logo: wallet.currencyLogo,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Failed to send ${wallet.currencyName}.',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 28,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ]
                            : [
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: Center(
                                    child: CoinSpinner(
                                      size: 160,
                                      logo: wallet.currencyLogo,
                                      spin: inProgressTransactionLoading,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  height: 25,
                                  child: Center(
                                    child: ProgressBar(
                                      switch (inProgressTransaction.state) {
                                        TransactionState.sending => 0,
                                        TransactionState.pending => 1,
                                        _ => 1,
                                      },
                                      width: width - 80,
                                      height: 16,
                                      borderRadius: 8,
                                      steps: [
                                        (
                                          0,
                                          (reached) => TransactionStateIcon(
                                                state: TransactionState.sending,
                                                color: reached
                                                    ? ThemeColors.primary
                                                        .resolveFrom(context)
                                                    : ThemeColors.white,
                                                duration: 750,
                                              )
                                        ),
                                        (
                                          1,
                                          (reached) => TransactionStateIcon(
                                                state: TransactionState.pending,
                                                color: reached
                                                    ? ThemeColors.primary
                                                        .resolveFrom(context)
                                                    : ThemeColors.white,
                                                duration: 750,
                                              )
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  inProgressTransaction.amount,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 46,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  wallet.symbol,
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 36,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'to',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 280),
                                      child: ProfileChip(
                                        selectedProfile: profileItem?.profile,
                                        selectedAddress: profileItem == null ||
                                                profileItem
                                                    .profile.account.isEmpty
                                            ? null
                                            : formatHexAddress(
                                                inProgressTransaction.to),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (!inProgressTransactionLoading &&
                                    inProgressTransaction.state ==
                                        TransactionState.pending) ...[
                                  Text(
                                    'on',
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    DateFormat.yMMMd().add_Hm().format(
                                        inProgressTransaction.date.toLocal()),
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 36,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ]
                              ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      width: width,
                      child: BlurryChild(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: ThemeColors.subtle.resolveFrom(context),
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: Column(children: [
                            Button(
                              text: 'Dismiss',
                              onPressed: () => handleDismiss(context),
                              minWidth: 200,
                              maxWidth: 200,
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
