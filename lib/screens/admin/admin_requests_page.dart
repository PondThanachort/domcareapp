import 'package:flutter/material.dart';
import '../../widgets/request_feed.dart';

class AdminRequestsPage extends StatelessWidget {
  const AdminRequestsPage({
    super.key,
    this.active = true,
    this.resetFilter = 0,
  });
  final bool active;
  final int resetFilter;
  @override
  Widget build(BuildContext context) =>
      RequestFeed(admin: true, active: active, resetFilter: resetFilter);
}
