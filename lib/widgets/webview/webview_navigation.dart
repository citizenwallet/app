import 'package:flutter/cupertino.dart';
import 'package:citizenwallet/theme/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WebViewNavigation extends StatelessWidget {
  final String? url;
  final VoidCallback onDismiss;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback? onRefresh;
  final bool canGoForward;
  final bool canGoBack;

  const WebViewNavigation({
    super.key,
    this.url,
    required this.onDismiss,
    this.onBack,
    this.onForward,
    this.onRefresh,
    this.canGoBack = false,
    this.canGoForward = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              if (onBack != null)
                const SizedBox(
                  width: 12,
                ),
              if (onBack != null)
                _buildNavButton(
                  context: context,
                  icon: CupertinoIcons.arrow_left,
                  onPressed: onBack!,
                  disabled: !canGoBack,
                ),
              if (onForward != null)
                const SizedBox(
                  width: 12,
                ),
              if (onForward != null)
                _buildNavButton(
                  context: context,
                  icon: CupertinoIcons.arrow_right,
                  onPressed: onForward!,
                  disabled: !canGoForward,
                ),
              if (onRefresh != null)
                const SizedBox(
                  width: 12,
                ),
              if (onRefresh != null)
                _buildNavButton(
                  context: context,
                  icon: CupertinoIcons.refresh,
                  onPressed: onRefresh!,
                ),
              if (url != null)
                const SizedBox(
                  width: 12,
                ),
              if (url != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context)
                            .colors
                            .surfaceBackground
                            .resolveFrom(context),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              url!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colors
                                    .surfaceText
                                    .resolveFrom(context),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            _buildNavButton(
              context: context,
              icon: CupertinoIcons.xmark,
              width: 44,
              onPressed: onDismiss,
            ),
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
    double width = 26,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: SizedBox(
        height: 44,
        width: width,
        child: Center(
          child: CupertinoButton(
            padding: const EdgeInsets.all(5),
            onPressed: disabled ? () => {} : onPressed,
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colors.touchable.resolveFrom(context),
            ),
          ),
        ),
      ),
    );
  }
}
