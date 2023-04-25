import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class TextInputModal extends StatelessWidget {
  late TextEditingController _controller;

  final String title;
  final String placeholder;
  final String initialValue;

  TextInputModal({
    super.key,
    this.title = 'Submit',
    this.placeholder = 'Enter text',
    this.initialValue = '',
  }) {
    _controller = TextEditingController(text: initialValue);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleSubmit(BuildContext context) {
    GoRouter.of(context).pop(_controller.value.text);
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleModalPopup(
      modalKey: 'text-input-modal',
      maxHeight: 300,
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
                  title: title,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CupertinoTextField(
                        controller: _controller,
                        placeholder: placeholder,
                        maxLines: 1,
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.done,
                        decoration: BoxDecoration(
                          color: const CupertinoDynamicColor.withBrightness(
                            color: CupertinoColors.white,
                            darkColor: CupertinoColors.black,
                          ),
                          border: Border.all(
                            color: ThemeColors.border.resolveFrom(context),
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5.0)),
                        ),
                        onSubmitted: (_) {
                          FocusManager.instance.primaryFocus?.unfocus();
                        },
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Confirm',
                            color: ThemeColors.primary.resolveFrom(context),
                            suffix: Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.doc_on_clipboard,
                                color: ThemeColors.white.resolveFrom(context),
                              ),
                            ),
                            onPressed: () => handleSubmit(context),
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
