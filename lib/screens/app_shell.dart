import 'package:flutter/material.dart';
import 'home_page.dart';
import 'requests_page.dart';
import 'profile_page.dart';
import '../widgets/floating_pill_navbar.dart';

class AppShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const AppShell({super.key, required this.onToggleTheme});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  List<Widget> get _pages => [
    const HomePage(),
    RequestsPage(active: _index == 1),
    ProfilePage(onToggleTheme: widget.onToggleTheme),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomNavigationBar: FloatingPillNavbar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
      floatingActionButton: _index == 2
          ? FloatingActionButton.small(
              onPressed: widget.onToggleTheme,
              child: const Icon(Icons.brightness_6_rounded),
            )
          : null,
    );
  }
}
