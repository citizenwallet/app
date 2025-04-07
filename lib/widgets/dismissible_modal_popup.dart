import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

class DismissibleModalPopup extends StatefulWidget {
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
  DismissibleModalPopupState createState() => DismissibleModalPopupState();
}

class DismissibleModalPopupState extends State<DismissibleModalPopup> {
  bool _dismissed = false;

  void onDismissed(DismissDirection dir) {
    setState(() {
      _dismissed = true;
    });

    if (widget.onDismissed != null) {
      widget.onDismissed!(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return const SizedBox();
    }

    return Dismissible(
      key: widget.modaleKey != null ? Key(widget.modaleKey!) : UniqueKey(),
      direction: DismissDirection.down,
      onUpdate: widget.onUpdate,
      onDismissed: onDismissed,
      confirmDismiss: (_) async {
        return !widget.blockDismiss;
      },
      child: Container(
        constraints: widget.maxHeight != null
            ? BoxConstraints(
                maxHeight: widget.maxHeight! +
                    MediaQuery.of(context).viewInsets.bottom,
              )
            : null,
        padding: EdgeInsets.fromLTRB(
          widget.paddingSides,
          widget.paddingTopBottom,
          widget.paddingSides,
          widget.paddingTopBottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colors.uiBackground.resolveFrom(context),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.topRadius),
            topRight: Radius.circular(widget.topRadius),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
