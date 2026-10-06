import 'package:flutter/material.dart';
import '../widgets/request_feed.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key, this.active = true});
  final bool active;
  @override
  Widget build(BuildContext context) => RequestFeed(active: active);
}
