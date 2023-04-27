import 'package:citizenwallet/state/wallet/logic.dart';
import 'package:citizenwallet/state/wallet/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PasswordModal extends StatefulWidget {
  final String address;
  final WalletLogic logic;

  const PasswordModal({
    Key? key,
    required this.address,
    required this.logic,
  }) : super(key: key);

  @override
  PasswordModalState createState() => PasswordModalState();
}

class PasswordModalState extends State<PasswordModal> {
  final TextEditingController controller = TextEditingController();
  final FocusNode messageFocusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here

      onLoad();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onLoad() async {
    final navigator = GoRouter.of(context);

    final dbwallet = await widget.logic.fetchDBWallet(widget.address);

    if (dbwallet == null) {
      navigator.pop();
      return;
    }

    final password =
        await widget.logic.tryUnlockWallet(dbwallet, widget.address);

    if (password == null) {
      return;
    }

    navigator.pop(password);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handlePasswordTry(String password) async {
    final navigator = GoRouter.of(context);

    final dbwallet = await widget.logic.fetchDBWallet(widget.address);

    if (dbwallet == null) return;

    final isValid = await widget.logic.verifyWalletPassword(dbwallet, password);

    if (!isValid) {
      return;
    }

    navigator.pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    final invalidPassword = context.select(
      (WalletState state) => state.isInvalidPassword,
    );

    return DismissibleModalPopup(
      maxHeight: height,
      paddingSides: 10,
      onUpdate: (details) {
        if (details.direction == DismissDirection.down &&
            FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      onDismissed: (_) => handleDismiss(context),
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: CupertinoPageScaffold(
          backgroundColor: ThemeColors.uiBackground.resolveFrom(context),
          child: SafeArea(
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  title: 'Unlock Wallet',
                  actionButton: CupertinoButton(
                    padding: const EdgeInsets.all(5),
                    onPressed: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Wallet password',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      CupertinoTextField(
                        controller: controller,
                        maxLines: 1,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (value) => handlePasswordTry(value),
                        decoration: invalidPassword
                            ? BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color: ThemeColors.danger,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              )
                            : BoxDecoration(
                                color:
                                    const CupertinoDynamicColor.withBrightness(
                                  color: CupertinoColors.white,
                                  darkColor: CupertinoColors.black,
                                ),
                                border: Border.all(
                                  color:
                                      ThemeColors.border.resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Unlock',
                            color: ThemeColors.primary.resolveFrom(context),
                            suffix: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.lock_open,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                            onPressed: () =>
                                handlePasswordTry(controller.value.text),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
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
