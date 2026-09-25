import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../widgets/neo_nav_bar.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    NeoNavBarItem(icon: LucideIcons.house, label: 'หน้าแรก'),
    NeoNavBarItem(icon: LucideIcons.bookmark, label: 'บันทึก'),
    NeoNavBarItem(icon: LucideIcons.clipboardList, label: 'ใบสมัคร'),
    NeoNavBarItem(icon: LucideIcons.userRound, label: 'โปรไฟล์'),
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
