import 'package:flutter/material.dart';

import 'floating_pill_navbar.dart';

class AdminNavbar extends StatelessWidget {
  const AdminNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingPillNavbar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        (Icons.dashboard_rounded, 'ภาพรวม'),
        (Icons.receipt_long_rounded, 'คำร้อง'),
        (Icons.people_alt_rounded, 'ผู้พัก'),
        (Icons.person_rounded, 'โปรไฟล์'),
      ],
    );
  }
}
