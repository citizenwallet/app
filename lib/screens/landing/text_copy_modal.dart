import 'package:citizenwallet/state/app/logic.dart';
import 'package:citizenwallet/state/app/state.dart';
import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class TextCopyModal extends StatelessWidget {
  final AppLogic logic;
  final String title;

  const TextCopyModal({
    super.key,
    required this.logic,
    this.title = 'Copy',
  });

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleCopy() {
    logic.copyPasswordToClipboard();
  }

  void handleDone(BuildContext context) {
    GoRouter.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.select((AppState state) => state.walletPassword);
    final hasCopied =
        context.select((AppState state) => state.hasCopiedPassword);

    return DismissibleModalPopup(
      modaleKey: 'landing-text-copy',
      maxHeight: 350,
      paddingSides: 10,
      blockDismiss: true,
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
                  title: title,
                  actionButton: GestureDetector(
                    onTap: () => handleDismiss(context),
                    child: Icon(
                      CupertinoIcons.xmark,
                      color: ThemeColors.touchable.resolveFrom(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              ThemeColors.subtleEmphasis.resolveFrom(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: SelectableText(
                          text,
                          style: TextStyle(
                            color: ThemeColors.touchable.resolveFrom(context),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: hasCopied ? 'Copied' : 'Copy',
                            color: ThemeColors.primary.resolveFrom(context),
                            suffix: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.square_on_square,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                            onPressed: handleCopy,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Continue',
                            color: ThemeColors.primary.resolveFrom(context),
                            suffix: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.square_on_square,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                            onPressed:
                                hasCopied ? () => handleDone(context) : null,
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 20,
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
