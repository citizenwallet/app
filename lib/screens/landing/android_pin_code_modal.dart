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

class AndroidPinCodeModal extends StatefulWidget {
  final String title = 'Account Backup';

  const AndroidPinCodeModal({
    Key? key,
  }) : super(key: key);

  @override
  AndroidPinCodeModalState createState() => AndroidPinCodeModalState();
}

class AndroidPinCodeModalState extends State<AndroidPinCodeModal> {
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

  void handleConfirmPinCodeChanged() {
    logic.onConfirmPinCodeChanged();
  }

  void handleIUnderstand() {
    logic.setIsUnderstood();
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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final pinCodeController =
        context.read<AndroidPinCodeState>().pinCodeController;
    final confirmPinCodeController =
        context.read<AndroidPinCodeState>().confirmPinCodeController;

    final isUnderstood = context.select(
      (AndroidPinCodeState state) => state.isUnderstood,
    );

    final hasPinCode = context.select(
      (AndroidPinCodeState state) => state.hasPinCode,
    );

    final isPinCodeValid = context.select(
      (AndroidPinCodeState state) => state.isPinCodeValid,
    );

    final isConfirmPinCodeValid = context.select(
      (AndroidPinCodeState state) => state.isConfirmPinCodeValid,
    );

    final isPinCodeMatch = context.select(
      (AndroidPinCodeState state) => state.isPinCodeMatch,
    );

    final isInvalid =
        isPinCodeValid && isConfirmPinCodeValid && !isPinCodeMatch;

    final canSetPinCode =
        isPinCodeValid && isConfirmPinCodeValid && isPinCodeMatch;

    return DismissibleModalPopup(
      modaleKey: 'landing-android-set-pin-code',
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
                if (!isUnderstood)
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
                                  "Backups use Android Auto Backup and follow your device's backup settings.",
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'If you install the app again on another device which shares the same Google account, the encrypted backup will be used to restore your accounts.',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Your accounts and your account backups are generated and owned by you.",
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "They can be manually exported at any time.",
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "You understand that losing access to the Google account on which your account backups are stored will mean that you could potentially lose access to those accounts.",
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 60),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Button(
                                      text: 'I understand',
                                      onPressed: handleIUnderstand,
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
                if (isUnderstood)
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
                                  'Setting a 6 digit pin code will allow your device to securely backup your accounts.',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'You will only be asked for this code again in case you need to set up the app again on a new device or if you re-install the app again on this device.',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'We do not store your pin code. Please note it down somewhere safe.',
                                  style: TextStyle(
                                    color:
                                        ThemeColors.text.resolveFrom(context),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Pin Code',
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
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
                                        decoration: isInvalid
                                            ? BoxDecoration(
                                                color:
                                                    const CupertinoDynamicColor
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
                                                color:
                                                    const CupertinoDynamicColor
                                                        .withBrightness(
                                                  color: CupertinoColors.white,
                                                  darkColor:
                                                      CupertinoColors.black,
                                                ),
                                                border: Border.all(
                                                  color: hasPinCode
                                                      ? ThemeColors.transparent
                                                          .resolveFrom(context)
                                                      : ThemeColors.border
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          handlePinCodeChanged();
                                          if (value.length == 6) {
                                            confirmPinCodeFocusNode
                                                .requestFocus();
                                          }
                                        },
                                        onSubmitted: (_) {
                                          confirmPinCodeFocusNode
                                              .requestFocus();
                                        },
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Confirm Pin Code',
                                      style: TextStyle(
                                        color: ThemeColors.text
                                            .resolveFrom(context),
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
                                        controller: confirmPinCodeController,
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
                                        decoration: isInvalid
                                            ? BoxDecoration(
                                                color:
                                                    const CupertinoDynamicColor
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
                                                color:
                                                    const CupertinoDynamicColor
                                                        .withBrightness(
                                                  color: CupertinoColors.white,
                                                  darkColor:
                                                      CupertinoColors.black,
                                                ),
                                                border: Border.all(
                                                  color: hasPinCode
                                                      ? ThemeColors.transparent
                                                          .resolveFrom(context)
                                                      : ThemeColors.border
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
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        focusNode: confirmPinCodeFocusNode,
                                        textInputAction: TextInputAction.done,
                                        onChanged: (_) =>
                                            handleConfirmPinCodeChanged(),
                                        onSubmitted: (_) => handleDone(),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (isInvalid)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Pin codes don't match",
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
                                      text: 'Set Pin Code',
                                      onPressed:
                                          !canSetPinCode ? null : handleDone,
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
