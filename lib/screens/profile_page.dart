import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onToggleTheme});

  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  child: Icon(Icons.person_rounded, size: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  AuthScope.userOf(context)?.displayName ?? 'สมชาย ใจดี',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'ผู้พักอาศัย · ห้อง ${AuthScope.userOf(context)?.room ?? '305'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _InfoRow(
                  icon: Icons.door_front_door_outlined,
                  label: 'ห้อง',
                  value: AuthScope.userOf(context)?.room ?? '305',
                ),
                _InfoRow(
                  icon: Icons.person_outline_rounded,
                  label: 'ชื่อผู้ใช้',
                  value: AuthScope.userOf(context)?.username ?? 'somchai305',
                ),
              ],
            ),
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
      (route) => false,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
