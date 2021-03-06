import 'package:flutter/material.dart';
import 'misc.dart';

/// See bottomNavigationBarItem or NavigationRailDestination
class AdaptiveScaffoldDestination {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  const AdaptiveScaffoldDestination({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}

/// A widget that adapts to the current display size, displaying a [Drawer],
/// [NavigationRail], or [BottomNavigationBar]. Navigation destinations are
/// defined in the [destinations] parameter.
class AdaptiveScaffold extends StatefulWidget {
  final Widget title;
  final List<Widget> actions;
  final Widget body;
  final int currentIndex;
  final List<AdaptiveScaffoldDestination> destinations;
  final ValueChanged<int> onNavigationIndexChange;

  AdaptiveScaffold({
    required this.title,
    required this.body,
    this.actions = const [],
    required this.currentIndex,
    required this.destinations,
    required this.onNavigationIndexChange,
  });

  @override
  _AdaptiveScaffoldState createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      // Show a navigation rail
      return Scaffold(
        appBar: AppBar(
          title: widget.title,
          actions: widget.actions,
        ),
        body: Row(
          children: [
            NavigationRail(
              destinations: [
                ...widget.destinations.map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.title),
                  ),
                ),
              ],
              selectedIndex: widget.currentIndex,
              onDestinationSelected: widget.onNavigationIndexChange,
              labelType: NavigationRailLabelType.all,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.grey[300],
            ),
            Expanded(
              child: widget.body,
            ),
          ],
        ),
      );
    } else {
      // Show a bottom app bar
      return Scaffold(
        body: widget.body,
        appBar: AppBar(
          title: widget.title,
          actions: widget.actions,
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: [
            ...widget.destinations.map(
              (d) => BottomNavigationBarItem(
                icon: Icon(d.icon),
                activeIcon: Icon(d.selectedIcon),
                label: d.title,
              ),
            ),
          ],
          currentIndex: widget.currentIndex,
          onTap: widget.onNavigationIndexChange,
        ),
      );
    }
  }
}
