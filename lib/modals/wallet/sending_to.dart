import 'package:citizenwallet/services/wallet/utils.dart';
import 'package:citizenwallet/state/notifications/logic.dart';
import 'package:citizenwallet/state/profiles/state.dart';
import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/ratio.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/profile/profile_chip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:rate_limiter/rate_limiter.dart';

import '../../widgets/wallet/coin_spinner.dart';

const List<Color> _kDefaultRainbowColors = [Color(0xFF9463D2)];

class SendingToScreen extends StatefulWidget {
  final WalletLogic walletLogic;
  const SendingToScreen({
    super.key,
    required this.walletLogic,
  });

  @override
  SendingToScreenState createState() => SendingToScreenState();
}

class SendingToScreenState extends State<SendingToScreen>
    with TickerProviderStateMixin {
  late WalletLogic _logic;
  late ScrollController _scrollController;

  late void Function() debouncedAddressUpdate;
  late void Function() debouncedAmountUpdate;
  @override
  void initState() {
    super.initState();

    _logic = widget.walletLogic;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController = ModalScrollController.of(context)!;

      //onLoad();

      debouncedAddressUpdate = debounce(
        _logic.updateAddress,
        const Duration(milliseconds: 500),
      );

      debouncedAmountUpdate = debounce(
        _logic.updateAmount,
        const Duration(milliseconds: 500),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedProfile = context.select(
      (ProfilesState state) => state.selectedProfile,
    );
    final wallet = context.select((WalletState state) => state.wallet);
    final coinSize = progressiveClamp(2, 40, 0);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: ThemeColors.background.resolveFrom(context),
        child: SafeArea(
          minimum: const EdgeInsets.only(left: 0, right: 0, top: 0),
          child: Flex(
            direction: Axis.vertical,
            children: [
              Container(
                width: 393,
                height: 750,
                padding: const EdgeInsets.only(
                  top: 0,
                  left: 16,
                  right: 16,
                  bottom: 32,
                ),
                clipBehavior: Clip.antiAlias,
                decoration: const ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Header(
                      color: ThemeColors.background,
                      titleWidget: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.send,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8F899C),
                                ),
                              ),
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.all(5),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Icon(
                              CupertinoIcons.xmark,
                              color: ThemeColors.touchable.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        //padding: const EdgeInsets.only(top: 84, bottom: 7),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 200,
                                          decoration: const BoxDecoration(),
                                          // padding: const EdgeInsets.symmetric(
                                          //     horizontal: 32, vertical: 0),
                                          child: Transform.scale(
                                            scale: 0.4,
                                            child: const LoadingIndicator(
                                              indicatorType:
                                                  Indicator.circleStrokeSpin,
                                              colors: _kDefaultRainbowColors,
                                              strokeWidth: 10.0,
                                              pathBackgroundColor:
                                                  Color.fromRGBO(81, 66, 66, 0),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Text(
                                        //   'Sent! 🎉',
                                        //   textAlign: TextAlign.center,
                                        //   style: TextStyle(
                                        //     color: Color(0xFF14013E),
                                        //     fontSize: 28,
                                        //     fontFamily: 'Inter',
                                        //     fontWeight: FontWeight.w600,
                                        //     height: 0.04,
                                        //     letterSpacing: 0.11,
                                        //   ),
                                        // ),
                                        Text(
                                          "Sending",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF14013E),
                                            fontSize: 28,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            height: 0.04,
                                            letterSpacing: 0.11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    CoinSpinner(
                                                        key: Key(
                                                            '${wallet?.alias}-spinner'),
                                                        size: coinSize,
                                                        logo: wallet!
                                                            .currencyLogo),
                                                    const SizedBox(
                                                        width: 16.77),
                                                    Text(
                                                      _logic.amountController
                                                          .value.text,
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF1E2122),
                                                        fontSize: 41.94,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 0.5,
                                                        letterSpacing: -0.11,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 16.77),
                                                    Text(
                                                      wallet.symbol,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 52, 52, 52),
                                                        fontSize: 17,
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        height: 0.08,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                width: 24,
                                                height: 24,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 7),
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [],
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Container(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    ProfileChip(
                                                      selectedProfile:
                                                          selectedProfile,
                                                      selectedAddress: _logic
                                                                  .addressController
                                                                  .value
                                                                  .text
                                                                  .isEmpty ||
                                                              selectedProfile !=
                                                                  null
                                                          ? null
                                                          : formatHexAddress(_logic
                                                              .addressController
                                                              .value
                                                              .text),
                                                      handleDeSelect: null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                padding:
                                                    const EdgeInsets.all(3),
                                                clipBehavior: Clip.antiAlias,
                                                decoration: BoxDecoration(),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Jul 17, 2023 - 17:38',
                                                style: TextStyle(
                                                  color: Color(0xFF8F899C),
                                                  fontSize: 16,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w600,
                                                  height: 0.09,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: double.infinity,
                      // padding:
                      //     const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF9463D2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CupertinoButton(
                            padding: const EdgeInsets.all(5),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "Done",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    ThemeColors.background.resolveFrom(context),
                              ),
                            ),
                          ),
                        ],
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
