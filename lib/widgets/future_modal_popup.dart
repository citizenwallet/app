import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class FutureModalPopup<T> extends StatelessWidget {
  final BuildContext context;
  final Widget child;
  final double? maxHeight;
  final double paddingSides;
  final double paddingTopBottom;
  final double topRadius;
  final Future<T> dissmisAfter;

  const FutureModalPopup({
    super.key,
    required this.context,
    required this.child,
    this.maxHeight = 200,
    this.paddingSides = 10,
    this.paddingTopBottom = 10,
    this.topRadius = 10,
    required this.dissmisAfter,
  });

  void handleDismiss() async {
    final navigator = GoRouter.of(context);

    final value = await dissmisAfter;

    navigator.pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(
              maxHeight: maxHeight! + MediaQuery.of(context).viewInsets.bottom,
            )
          : null,
      padding: EdgeInsets.fromLTRB(
        paddingSides,
        paddingTopBottom,
        paddingSides,
        paddingTopBottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colors.uiBackground.resolveFrom(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topRadius),
          topRight: Radius.circular(topRadius),
        ),
      ),
      child: child,
    );
  }
}
