import 'package:flutter/material.dart';

import 'coming_soon_tab.dart';
import 'dashboard_screen.dart';

/// The main app after signing in: four tabs with a bottom navigation bar.
///
/// IndexedStack keeps every tab alive, so switching tabs doesn't reset
/// scroll position or what was typed.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Vitals, Alerts and Settings are placeholders until their screens are built.
  static const _tabs = <Widget>[
    DashboardScreen(),
    ComingSoonTab(kicker: 'Monitoring data', title: 'Vital Signs History', icon: Icons.show_chart),
    ComingSoonTab(kicker: 'History', title: 'Alerts & Events', icon: Icons.notifications_none),
    ComingSoonTab(kicker: 'Account', title: 'Profile & Settings', icon: Icons.settings_outlined, showSignOut: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.monitor_heart_outlined), selectedIcon: Icon(Icons.monitor_heart), label: 'Vitals'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
