import 'package:flutter/material.dart';
import '../../widgets/request_feed.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    this.active = true,
    required this.onViewAll,
  });
  final bool active;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context) => RequestFeed(
    admin: true,
    dashboard: true,
    active: active,
    onViewAll: onViewAll,
  );
}
