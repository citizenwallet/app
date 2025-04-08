import 'package:flutter/cupertino.dart';

class BottomTabBarItem {
  final String label;
  final IconData? icon;
  final Widget? customIcon;

  const BottomTabBarItem({
    required this.label,
    this.icon,
    this.customIcon,
  });
}

class BottomTabBar extends StatefulWidget {
  final List<BottomTabBarItem> items;
  final int selectedIndex;
  final void Function(int) onItemSelected;

  const BottomTabBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  BottomTabBarState createState() => BottomTabBarState();
}

class BottomTabBarState extends State<BottomTabBar> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      items: [
        for (final item in widget.items)
          BottomNavigationBarItem(
            label: item.label,
            icon: item.icon != null
                ? Icon(item.icon)
                : item.customIcon ?? const SizedBox(),
          ),
      ],
      currentIndex: widget.selectedIndex,
      onTap: widget.onItemSelected,
    );
  }
}
