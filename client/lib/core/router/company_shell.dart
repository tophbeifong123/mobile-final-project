import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/neo_nav_bar.dart';

class CompanyShell extends StatelessWidget {
  const CompanyShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    NeoNavBarItem(icon: LucideIcons.layoutDashboard, label: 'Dashboard'),
    NeoNavBarItem(icon: LucideIcons.briefcase, label: 'Jobs'),
    NeoNavBarItem(icon: LucideIcons.building2, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NeoNavBar(
        selectedIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: _items,
      ),
    );
  }
}
