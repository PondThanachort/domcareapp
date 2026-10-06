import 'package:flutter/material.dart';
import '../models/repair_request.dart';
import '../services/auth_service.dart';
import '../screens/live_request_detail_page.dart';
import 'request_card.dart';

/// The dashboard and both lists share API loading, refresh and error handling.
class RequestFeed extends StatefulWidget {
  const RequestFeed({
    super.key,
    this.admin = false,
    this.dashboard = false,
    this.active = true,
    this.onViewAll,
    this.resetFilter = 0,
  });
  final bool admin, dashboard, active;
  final VoidCallback? onViewAll;
  final int resetFilter;
  @override
  State<RequestFeed> createState() => _RequestFeedState();
}

class _RequestFeedState extends State<RequestFeed> {
  AuthSession? _session;
  int _revision = -1, _loadId = 0;
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  List<RepairRequest> _requests = [];
  Map<String, dynamic> _counts = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context);
    if (_session != session || _revision != session.requestsRevision) {
      _session = session;
      _revision = session.requestsRevision;
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant RequestFeed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetFilter != widget.resetFilter) _filter = 'all';
    if (!oldWidget.active && widget.active) _load();
  }

  Future<void> _load() async {
    final session = _session;
    if (session?.token == null) return;
    final loadId = ++_loadId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await session!.service.authorizedRequest(
        'GET',
        widget.dashboard ? '/api/requests?limit=3' : '/api/requests',
        session.token!,
      );
      final requests = (data['requests'] as List)
          .map((r) => RepairRequest.fromJson(r as Map<String, dynamic>))
          .toList();
      if (!mounted || loadId != _loadId) return;
      setState(() {
        _requests = requests;
        _counts = data['counts'] as Map<String, dynamic>;
      });
    } catch (error) {
      if (!mounted || loadId != _loadId) return;
      setState(
        () => _error = error is AuthException
            ? error.message
            : 'ไม่สามารถอ่านข้อมูลคำร้องได้',
      );
    } finally {
      if (mounted && loadId == _loadId) setState(() => _loading = false);
    }
  }

  Future<void> _open(RepairRequest request) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveRequestDetailPage(id: request.id),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = {'all': 'ทั้งหมด', ...RepairRequest.statuses};
    final visible = _requests.where(
      (r) => _filter == 'all' || r.status == _filter,
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
        children: [
          Text(
            widget.dashboard
                ? 'ภาพรวม'
                : widget.admin
                ? 'คำร้องทั้งหมด'
                : 'คำร้องของฉัน',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.dashboard
                ? 'ผู้ดูแลระบบ'
                : widget.admin
                ? 'ตรวจสอบและอัปเดตสถานะคำร้องของผู้พัก'
                : 'ติดตามสถานะคำร้องทั้งหมดของคุณ',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          if (!widget.dashboard && widget.admin)
            DropdownButtonFormField<String>(
              key: ValueKey('admin-status-filter-${widget.resetFilter}'),
              initialValue: _filter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'กรองสถานะคำร้อง',
                prefixIcon: Icon(Icons.filter_list_rounded),
              ),
              items: filters.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _filter = value!),
            ),
          if (!widget.dashboard && !widget.admin)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in filters.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: ValueKey(entry.key),
                        label: Text(entry.value),
                        selected: _filter == entry.key,
                        showCheckmark: false,
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surface,
                        labelStyle: TextStyle(
                          color: _filter == entry.key
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        onSelected: (_) => setState(() => _filter = entry.key),
                      ),
                    ),
                ],
              ),
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            TextButton(onPressed: _load, child: const Text('ลองใหม่')),
          ],
          if (!_loading && _error == null) ...[
            if (widget.dashboard) ...[
              for (final pair in [
                ['pending', 'in_progress'],
                ['completed', 'total'],
              ]) ...[
                SizedBox(
                  height: 110,
                  child: Row(
                    children: [
                      for (final status in pair) ...[
                        Expanded(
                          child: _DashboardStat(
                            status: status,
                            value: '${_counts[status] ?? 0}',
                          ),
                        ),
                        if (status == pair.first) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'คำร้องล่าสุด',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('ดูทั้งหมด'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('ไม่มีคำร้องในสถานะนี้')),
              ),
            for (final request in visible) ...[
              RequestCard(
                icon: request.icon,
                title: request.title,
                subtitle:
                    'ห้อง ${request.room} · ${widget.admin ? request.resident : request.date}',
                status:
                    RepairRequest.statuses[request.status] ?? request.status,
                statusColor: request.color,
                onTap: () => _open(request),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({required this.status, required this.value});
  final String status, value;
  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      'pending' => (Icons.schedule_rounded, const Color(0xFFF59E0B)),
      'in_progress' => (Icons.build_circle_rounded, const Color(0xFF6A75FF)),
      'completed' => (Icons.check_circle_rounded, const Color(0xFF24A66A)),
      _ => (Icons.receipt_long_rounded, const Color(0xFF64748B)),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    status == 'total'
                        ? 'คำร้องทั้งหมด'
                        : RepairRequest.statuses[status]!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
