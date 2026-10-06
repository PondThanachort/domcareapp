import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.authService});
  final AuthService? authService;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final AuthSession _session = AuthSession(_authService);

  @override
  void dispose() {
    _session.dispose();
    if (widget.authService == null) _authService.dispose();
    super.dispose();
  }

  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      session: _session,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DormCare',
        themeMode: _themeMode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: LoginPage(onToggleTheme: _toggleTheme),
      ),
    );
  }
}
