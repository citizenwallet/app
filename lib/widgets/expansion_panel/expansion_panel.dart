import 'package:citizenwallet/theme/provider.dart';
import 'package:flutter/cupertino.dart';

// TODO: pass in dontCollapse boolean. True if only one item exists in child

class CupertinoExpansionPanel extends StatefulWidget {
  final Widget title;
  final Widget child;

  const CupertinoExpansionPanel({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  CupertinoExpansionPanelState createState() => CupertinoExpansionPanelState();
}

class CupertinoExpansionPanelState extends State<CupertinoExpansionPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sizeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      _isExpanded
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colors.transparent,
            ),
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.title,
                RotationTransition(
                  turns: Tween<double>(
                    begin: 0.0,
                    end: 0.5, // Rotate 180 degrees to point up
                  ).animate(_animationController),
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 20.0,
                    color:
                        Theme.of(context).colors.primary.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          SizeTransition(
            sizeFactor: _sizeAnimation,
            axisAlignment: -1.0, // Aligns the child to the top when expanding
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
