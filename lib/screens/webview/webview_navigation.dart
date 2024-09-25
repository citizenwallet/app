import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/theme/provider.dart';

class WebViewNavigation extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onRefresh;

  const WebViewNavigation({
    super.key,
    required this.onDismiss,
    required this.onBack,
    required this.onForward,
    required this.onRefresh,
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
            ),
            const SizedBox(
              width: 20,
            ),
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.arrow_right,
              onPressed: onForward,
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
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.xmark,
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
  }) {
    return Container(
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
          onPressed: onPressed,
          child: Icon(
            icon,
            color: Theme.of(context).colors.touchable.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}
