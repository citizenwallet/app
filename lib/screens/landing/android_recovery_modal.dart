import 'package:citizenwallet/state/android_pin_code/logic.dart';
import 'package:citizenwallet/state/android_pin_code/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AndroidRecoveryModal extends StatefulWidget {
  final String title = 'Account Recovery';

  const AndroidRecoveryModal({
    Key? key,
  }) : super(key: key);

  @override
  AndroidRecoveryModalState createState() => AndroidRecoveryModalState();
}

class AndroidRecoveryModalState extends State<AndroidRecoveryModal> {
  final FocusNode confirmPinCodeFocusNode = FocusNode();
  late AndroidPinCodeLogic logic;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // make initial requests here
      logic = AndroidPinCodeLogic(context);
    });
  }

  void handlePinCodeChanged() {
    logic.onPinCodeChanged();
  }

  void handleDone() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final navigator = GoRouter.of(context);

    final String pinCode = context.read<AndroidPinCodeState>().pinCode;

    final success = await logic.configureBackup(pinCode);

    if (!success) {
      return;
    }

    TextInput.finishAutofillContext();

    navigator.pop();
  }

  void handleFromScratch() async {
    final navigator = GoRouter.of(context);

    await logic.clearDataAndBackups();

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final pinCodeController =
        context.read<AndroidPinCodeState>().pinCodeController;

    final hasPinCode = context.select(
      (AndroidPinCodeState state) => state.hasPinCode,
    );

    final isPinCodeValid = context.select(
      (AndroidPinCodeState state) => state.isPinCodeValid,
    );

    final invalidRecoveryPin = context.select(
      (AndroidPinCodeState state) => state.invalidRecoveryPin,
    );

    return DismissibleModalPopup(
      modaleKey: 'landing-android-recover-backup',
      maxHeight: height,
      paddingSides: 10,
      blockDismiss: true,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
          child: SafeArea(
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  title: widget.title,
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'It looks like there is an account backup available on this Google account.',
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Please provide the pin code that was used to set up this backup in order to use it.',
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Pin Code',
                                    style: TextStyle(
                                      color:
                                          ThemeColors.text.resolveFrom(context),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 220,
                                    child: CupertinoTextField(
                                      controller: pinCodeController,
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      prefix: const SizedBox(width: 10),
                                      autofillHints: const [
                                        AutofillHints.password
                                      ],
                                      decoration: invalidRecoveryPin
                                          ? BoxDecoration(
                                              color: const CupertinoDynamicColor
                                                  .withBrightness(
                                                color: CupertinoColors.white,
                                                darkColor:
                                                    CupertinoColors.black,
                                              ),
                                              border: Border.all(
                                                color: ThemeColors.danger,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(5.0)),
                                            )
                                          : BoxDecoration(
                                              color: const CupertinoDynamicColor
                                                  .withBrightness(
                                                color: CupertinoColors.white,
                                                darkColor:
                                                    CupertinoColors.black,
                                              ),
                                              border: Border.all(
                                                color: hasPinCode
                                                    ? ThemeColors.transparent
                                                        .resolveFrom(context)
                                                    : ThemeColors.text
                                                        .resolveFrom(context),
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(5.0)),
                                            ),
                                      maxLines: 1,
                                      maxLength: 6,
                                      obscureText: true,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      textInputAction: TextInputAction.done,
                                      onChanged: (value) {
                                        handlePinCodeChanged();
                                        if (value.length == 6) {
                                          handleDone();
                                        }
                                      },
                                      onSubmitted: (_) {
                                        handleDone();
                                      },
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (invalidRecoveryPin)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Invalid pin code',
                                      style: TextStyle(
                                        color: ThemeColors.danger
                                            .resolveFrom(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 60),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Button(
                                    text: 'Recover',
                                    onPressed:
                                        !isPinCodeValid ? null : handleDone,
                                    minWidth: 200,
                                    maxWidth: 200,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                              Text(
                                'Danger Zone',
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'I would like to delete this backup and start from scratch.',
                                style: TextStyle(
                                  color: ThemeColors.text.resolveFrom(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Button(
                                    text: 'Start from scratch',
                                    color:
                                        ThemeColors.danger.resolveFrom(context),
                                    onPressed: handleFromScratch,
                                    minWidth: 200,
                                    maxWidth: 200,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 60),
                            ],
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
      ),
    );
  }
}
