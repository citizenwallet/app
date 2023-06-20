import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class TextInputModal extends StatefulWidget {
  final String title;
  final String placeholder;
  final String initialValue;
  final bool secure;
  final bool confirm;
  final bool retry;

  const TextInputModal({
    super.key,
    this.title = 'Submit',
    this.placeholder = 'Enter text',
    this.initialValue = '',
    this.secure = false,
    this.confirm = false,
    this.retry = false,
  });

  @override
  TextInputModalState createState() => TextInputModalState();
}

class TextInputModalState extends State<TextInputModal> {
  late TextEditingController _controller;
  final TextEditingController _confirmController = TextEditingController();

  final FocusNode focusNode = FocusNode();

  bool _invalid = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleSubmit(BuildContext context) {
    if (widget.confirm) {
      focusNode.requestFocus();
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    GoRouter.of(context).pop(_controller.value.text);
  }

  void handleSubmitConfirm(BuildContext context) {
    final isMatching = _controller.value.text == _confirmController.value.text;
    if (!isMatching) {
      setState(() {
        _invalid = true;
      });

      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _invalid = false;
    });

    HapticFeedback.lightImpact();
    GoRouter.of(context).pop(_controller.value.text);
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleModalPopup(
      modaleKey: 'text-input-modal',
      maxHeight: 350,
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
                  title: widget.title,
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      CupertinoTextField(
                        controller: _controller,
                        placeholder: widget.placeholder,
                        maxLines: 1,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        obscureText: widget.secure,
                        autofillHints: widget.secure
                            ? const [
                                AutofillHints.password,
                              ]
                            : null,
                        textInputAction: widget.confirm
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: BoxDecoration(
                          color: const CupertinoDynamicColor.withBrightness(
                            color: CupertinoColors.white,
                            darkColor: CupertinoColors.black,
                          ),
                          border: _invalid || widget.retry == true
                              ? Border.all(
                                  color:
                                      ThemeColors.danger.resolveFrom(context),
                                )
                              : Border.all(
                                  color:
                                      ThemeColors.border.resolveFrom(context),
                                ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(5.0)),
                        ),
                        onSubmitted: (_) {
                          handleSubmit(context);
                        },
                      ),
                      if (widget.confirm)
                        const SizedBox(
                          height: 20,
                        ),
                      if (widget.confirm)
                        const Text(
                          'Confirm',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      if (widget.confirm)
                        const SizedBox(
                          height: 10,
                        ),
                      if (widget.confirm)
                        CupertinoTextField(
                          controller: _confirmController,
                          placeholder: widget.placeholder,
                          maxLines: 1,
                          autofocus: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          obscureText: widget.secure,
                          autofillHints: widget.secure
                              ? const [
                                  AutofillHints.password,
                                ]
                              : null,
                          textInputAction: TextInputAction.done,
                          focusNode: focusNode,
                          decoration: BoxDecoration(
                            color: const CupertinoDynamicColor.withBrightness(
                              color: CupertinoColors.white,
                              darkColor: CupertinoColors.black,
                            ),
                            border: _invalid
                                ? Border.all(
                                    color:
                                        ThemeColors.danger.resolveFrom(context),
                                  )
                                : Border.all(
                                    color:
                                        ThemeColors.border.resolveFrom(context),
                                  ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5.0)),
                          ),
                          onSubmitted: (_) {
                            handleSubmitConfirm(context);
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
                            color:
                                ThemeColors.surfacePrimary.resolveFrom(context),
                            labelColor: ThemeColors.black,
                            suffix: const Padding(
                              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                              child: Icon(
                                CupertinoIcons.square_on_square,
                                size: 14,
                                color: ThemeColors.black,
                              ),
                            ),
                            onPressed: widget.confirm
                                ? () => handleSubmitConfirm(context)
                                : () => handleSubmit(context),
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
