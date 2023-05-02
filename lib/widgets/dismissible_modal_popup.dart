import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class DismissibleModalPopup extends StatelessWidget {
  final String? modaleKey;
  final Widget child;
  final double? maxHeight;
  final double paddingSides;
  final double paddingTopBottom;
  final double topRadius;
  final void Function(DismissUpdateDetails)? onUpdate;
  final void Function(DismissDirection)? onDismissed;
  final bool blockDismiss;

  const DismissibleModalPopup({
    super.key,
    required this.child,
    this.modaleKey,
    this.maxHeight = 200,
    this.paddingSides = 10,
    this.paddingTopBottom = 10,
    this.topRadius = 10,
    this.onUpdate,
    this.onDismissed,
    this.blockDismiss = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: modaleKey != null ? Key(modaleKey!) : UniqueKey(),
      direction: DismissDirection.down,
      onUpdate: onUpdate,
      onDismissed: onDismissed,
      confirmDismiss: (_) async {
        return !blockDismiss;
      },
      child: Container(
        constraints: maxHeight != null
            ? BoxConstraints(
                maxHeight:
                    maxHeight! + MediaQuery.of(context).viewInsets.bottom,
              )
            : null,
        padding: EdgeInsets.fromLTRB(
          paddingSides,
          paddingTopBottom,
          paddingSides,
          paddingTopBottom,
        ),
        decoration: BoxDecoration(
          color: ThemeColors.uiBackground.resolveFrom(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(topRadius),
            topRight: Radius.circular(topRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
