import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

import '../login_page.dart';

class AdminProfilePage extends StatelessWidget {
  const AdminProfilePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'โปรไฟล์',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton.icon(
              onPressed: () => _logout(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFFC62828),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 19),
              label: const Text(
                'ออกจากระบบ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: dark ? Colors.white : const Color(0xFF111113),
              foregroundColor: dark ? const Color(0xFF111113) : Colors.white,
              child: const Icon(Icons.admin_panel_settings_rounded),
            ),
            title: Text(
              AuthScope.userOf(context)?.displayName ?? 'ผู้ดูแลระบบ',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(AuthScope.userOf(context)?.username ?? 'admin'),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            leading: const Icon(Icons.brightness_6_rounded),
            title: const Text('เปลี่ยน Light / Dark mode'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onToggleTheme,
          ),
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    AuthScope.of(context).logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(onToggleTheme: onToggleTheme),
      ),
      (_) => false,
    );
  }
}
