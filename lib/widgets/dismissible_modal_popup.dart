import 'package:citizenwallet/theme/colors.dart';
import 'package:flutter/cupertino.dart';

class DismissibleModalPopup extends StatelessWidget {
  final Widget child;
  final String modalKey;
  final int maxHeight;
  final double paddingSides;
  final double topRadius;
  final void Function(DismissUpdateDetails)? onUpdate;
  final void Function(DismissDirection)? onDismissed;

  const DismissibleModalPopup({
    super.key,
    required this.child,
    required this.modalKey,
    this.maxHeight = 300,
    this.paddingSides = 10,
    this.topRadius = 10,
    this.onUpdate,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(modalKey),
      direction: DismissDirection.down,
      onUpdate: onUpdate,
      onDismissed: onDismissed,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: maxHeight + MediaQuery.of(context).viewInsets.bottom,
        ),
        padding: EdgeInsets.fromLTRB(paddingSides, 10, paddingSides, 10),
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
