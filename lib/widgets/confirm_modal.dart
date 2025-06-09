import 'package:citizenwallet/theme/provider.dart';
import 'package:citizenwallet/widgets/button.dart';
import 'package:citizenwallet/widgets/dismissible_modal_popup.dart';
import 'package:citizenwallet/widgets/header.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:citizenwallet/l10n/app_localizations.dart';

const List<String> emptyDetails = [];

class ConfirmModal extends StatelessWidget {
  final String? title;
  final List<String> details;
  final String? confirmText;

  const ConfirmModal({
    super.key,
    this.title,
    this.details = emptyDetails,
    this.confirmText,
  });

  void handleDismiss(BuildContext context) {
    GoRouter.of(context).pop(false);
  }

  void handleConfirm(BuildContext context) {
    GoRouter.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return DismissibleModalPopup(
      modaleKey: 'confirm-modal',
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
          backgroundColor:
              Theme.of(context).colors.uiBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Flex(
              direction: Axis.vertical,
              children: [
                Header(
                  title: title ?? AppLocalizations.of(context)!.confirm,
                  color: Theme.of(context)
                      .colors
                      .uiBackground
                      .resolveFrom(context),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...details
                          .map(
                            (d) => Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      const SizedBox(
                        height: 40,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Button(
                            text: 'Cancel',
                            minWidth: 140,
                            maxWidth: 140,
                            color: Theme.of(context)
                                .colors
                                .subtleEmphasis
                                .resolveFrom(context),
                            onPressed: () => handleDismiss(context),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Button(
                            text: confirmText ?? 'Delete account',
                            minWidth: 140,
                            maxWidth: 140,
                            color: Theme.of(context)
                                .colors
                                .danger
                                .resolveFrom(context),
                            onPressed: () => handleConfirm(context),
                          ),
                        ],
                      )
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
