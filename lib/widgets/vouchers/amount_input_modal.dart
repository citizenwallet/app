import 'package:citizenwallet/theme/colors.dart';
import 'package:citizenwallet/utils/currency.dart';
import 'package:citizenwallet/utils/formatters.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AmountInputModal extends StatefulWidget {
  final String title;
  final String placeholder;
  final String symbol;
  final String initialValue;
  final bool retry;

  const AmountInputModal({
    super.key,
    this.title = 'Submit',
    this.placeholder = 'Enter text',
    this.symbol = '',
    this.initialValue = '',
    this.retry = false,
  });

  @override
  TextInputModalState createState() => TextInputModalState();
}

class TextInputModalState extends State<AmountInputModal> {
  late TextEditingController _controller;

  final FocusNode focusNode = FocusNode();
  final AmountFormatter amountFormatter = AmountFormatter();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);

    // post frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // initial requests go here
      onLoad();
    });
  }

  void onLoad() {
    focusNode.requestFocus();
  }

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop();
  }

  void handleSubmit(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.lightImpact();
    GoRouter.of(context).pop(_controller.value.text);
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleModalPopup(
      modaleKey: 'amount-input-modal',
      maxHeight: 240,
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
            top: false,
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  title: widget.title,
                  color: ThemeColors.uiBackground.resolveFrom(context),
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
                        placeholder: formatCurrency(0.00, ''),
                        style: TextStyle(
                          color: ThemeColors.text.resolveFrom(context),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        decoration: _controller.value.text.isNotEmpty &&
                                double.parse(_controller.value.text) <= 0
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
                                  color: _controller.value.text.isNotEmpty
                                      ? ThemeColors.text.resolveFrom(context)
                                      : ThemeColors.transparent
                                          .resolveFrom(context),
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                              ),
                        maxLines: 1,
                        maxLength: 25,
                        focusNode: focusNode,
                        autocorrect: false,
                        enableSuggestions: false,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: false,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          amountFormatter,
                        ],
                        onSubmitted: (_) {
                          handleSubmit(context);
                        },
                        prefix: Center(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: Text(
                              widget.symbol,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                            ),
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
