import 'package:flutter/material.dart';

class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  const MobileBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: const Color(0xFF8B7355),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map),
          label: 'Live City Map',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Assigned Tasks',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart),
          label: 'Performance',
        ),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }
}
