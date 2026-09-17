import 'package:flutter/material.dart';

class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,

      backgroundColor: const Color(0xFF0D111A),
      indicatorColor: const Color(0xFF1D356D),

      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.gamepad_outlined),
          selectedIcon: Icon(Icons.gamepad_rounded),
          label: 'Télécommande',
        ),

        NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps_rounded),
          label: 'Apps',
        ),

        NavigationDestination(
          icon: Icon(Icons.tv),
          selectedIcon: Icon(Icons.tv_rounded),
          label: 'TV',
        ),

        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'Réglages',
        ),
      ],
    );
  }
}
