import 'dart:async';

import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:citizenwallet/widgets/slide_to_complete.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SendForm extends StatefulWidget {
  final WalletLogic logic;

  const SendForm({Key? key, required this.logic}) : super(key: key);

  @override
  SendFormState createState() => SendFormState();
}

class SendFormState extends State<SendForm> with TickerProviderStateMixin {
  late final AnimationController _controller;

  bool _isSending = false;
  double _percentage = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleDismiss(BuildContext context) {
    Navigator.of(context).pop();
  }

  void handleSend(BuildContext context) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    HapticFeedback.lightImpact();

    _controller.repeat();

    final navigator = Navigator.of(context);

    await Future.delayed(const Duration(milliseconds: 1000));

    await widget.logic.sendTransaction(
        100, dotenv.get('TEST_DESTINATION_ADDRESS'),
        message: 'hello world');

    HapticFeedback.heavyImpact();

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.select((WalletState state) => state.transactionSendLoading);

    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return DismissibleModalPopup(
      modalKey: 'send-form',
      maxHeight: height - 20,
      paddingSides: 10,
      onDismissed: (_) => handleDismiss(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Header(
            title: 'Send',
            manualBack: true,
            actionButton: GestureDetector(
              onTap: () => handleDismiss(context),
              child: Icon(
                CupertinoIcons.xmark,
                color: ThemeColors.touchable.resolveFrom(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'To',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Amount',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Message',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/wallet_loader.json',
                    height: (_percentage * 100),
                    width: (_percentage * 100),
                    controller: _controller,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SlideToComplete(
                onCompleted: !_isSending ? () => handleSend(context) : null,
                isComplete: _isSending,
                onSlide: (percentage) {
                  if (percentage == 1) {
                    setState(() {
                      _percentage = 1;
                    });
                  } else {
                    setState(() {
                      _percentage = percentage;
                    });
                  }
                },
                completionLabel: _isSending ? 'Sending...' : 'Slide to send',
                thumbColor: ThemeColors.primary.resolveFrom(context),
                width: width * 0.8,
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.arrow_right,
                      color: ThemeColors.white.resolveFrom(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
