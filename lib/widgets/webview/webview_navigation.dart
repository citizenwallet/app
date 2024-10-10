import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WebViewNavigation extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onRefresh;
  final bool canGoForward;
  final bool canGoBack;

  const WebViewNavigation({
    super.key,
    required this.onDismiss,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20,
            ),
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.arrow_left,
              onPressed: onBack,
              disabled: !canGoBack,
            ),
            const SizedBox(
              width: 20,
            ),
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.arrow_right,
              onPressed: onForward,
              disabled: !canGoForward,
            ),
            const SizedBox(
              width: 20,
            ),
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.refresh,
              onPressed: onRefresh,
            ),
          ],
        ),
        Row(
          children: [
            _buildCloseButton(
              context: context,
              onPressed: onDismiss,
            ),
            const SizedBox(
              width: 20,
            )
          ],
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    bool disabled = false,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colors
              .uiBackground
              .resolveFrom(context)
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: CupertinoButton(
            padding: const EdgeInsets.all(5),
            onPressed: disabled ? () => {} : onPressed,
            child: Icon(
              icon,
              color: Theme.of(context).colors.touchable.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      onPressed: onPressed,
      child: Container(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.close,
              style: TextStyle(
                  color: Theme.of(context).colors.primary, fontSize: 12),
            ),
          )),
    );
  }
}
