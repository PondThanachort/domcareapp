import 'package:flutter/material.dart';

import '../../widgets/admin_navbar.dart';

import 'admin_dashboard_page.dart';
import 'admin_profile_page.dart';
import 'admin_requests_page.dart';
import 'admin_residents_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  int _resetFilter = 0;

  List<Widget> get _pages => [
    AdminDashboardPage(
      active: _index == 0,
      onViewAll: () => setState(() {
        _resetFilter++;
        _index = 1;
      }),
    ),
    AdminRequestsPage(active: _index == 1, resetFilter: _resetFilter),
    const AdminResidentsPage(),
    AdminProfilePage(onToggleTheme: widget.onToggleTheme),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: AdminNavbar(
        currentIndex: _index,
        onTap: (index) => setState(() => _index = index),
      ),
      floatingActionButton: _index == 3
          ? FloatingActionButton.small(
              onPressed: widget.onToggleTheme,
              tooltip: 'เปลี่ยน Light / Dark mode',
              child: const Icon(Icons.brightness_6_rounded),
            )
          : null,
    );
  }
}
