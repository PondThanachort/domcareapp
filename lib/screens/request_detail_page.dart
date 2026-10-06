import 'package:flutter/material.dart';
import '../models/mock_resident_request.dart';
import 'edit_request_page.dart';

class RequestDetailPage extends StatefulWidget {
  const RequestDetailPage({super.key, required this.request});
  final MockResidentRequest request;
  @override
  State<RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<RequestDetailPage> {
  Future<void> _cancel() async {
    if (!widget.request.canEdit) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelRequestDialog(),
    );
    if (!mounted || reason == null) return;
    if (widget.request.cancel(reason)) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดคำร้อง'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _Section(
            children: [
              Text(
                '${request.id} · ข้อมูลตัวอย่าง',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(request.icon, color: request.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      request.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Chip(label: Text(MockResidentRequest.labels[request.status]!)),
              const SizedBox(height: 16),
              _Info(
                icon: Icons.category_outlined,
                label: 'หมวดหมู่',
                value: request.category,
              ),
              const _Info(
                icon: Icons.door_front_door_outlined,
                label: 'ห้อง',
                value: '305',
              ),
              _Info(
                icon: Icons.schedule_rounded,
                label: 'วันที่แจ้ง',
                value: request.date,
              ),
              const Divider(height: 28),
              Text('รายละเอียด', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(request.description, style: theme.textTheme.bodyLarge),
              if (request.cancellationReason != null) ...[
                const Divider(height: 28),
                Text('เหตุผลการยกเลิก', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  request.cancellationReason!,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ],
          ),
          if (request.canEdit) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('แก้ไขคำร้อง'),
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => EditRequestPage(request: request),
                  ),
                );
                if (mounted) setState(() {});
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('ยกเลิกคำร้อง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              onPressed: _cancel,
            ),
          ],
          const SizedBox(height: 16),
          _Section(
            children: [
              Text('รูปภาพ', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              const Text('ยังไม่มีรูปภาพแนบในข้อมูลตัวอย่างนี้'),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            children: [
              Text('สถานะการดำเนินการ', style: theme.textTheme.titleLarge),
              const SizedBox(height: 20),
              _TimelineItem(
                title: 'รอดำเนินการ',
                detail: '${request.date} เวลา 09:30\nสมชาย ใจดี · ส่งคำร้อง',
                done: true,
                last: request.history.isEmpty && request.status == 'pending',
              ),
              if (request.status == 'in_progress') ...[
                _TimelineItem(
                  title: 'กำลังตรวจสอบ/ซ่อม',
                  detail:
                      '${request.date} เวลา 11:20\nผู้ดูแลระบบ · ติดต่อช่างเพื่อตรวจสอบแล้ว',
                  current: true,
                ),
                const _TimelineItem(
                  title: 'เสร็จสิ้น',
                  detail: 'รอผู้ดูแลอัปเดตสถานะ',
                  last: true,
                ),
              ],
              for (var i = 0; i < request.history.length; i++)
                _TimelineItem(
                  title: request.history[i].title,
                  detail:
                      '${_time(request.history[i].time)}\n${request.history[i].actor} · ${request.history[i].note}',
                  done: true,
                  last: i == request.history.length - 1,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            children: [
              Text('หมายเหตุจากผู้ดูแล', style: theme.textTheme.titleMedium),
              const SizedBox(height: 10),
              Text(
                request.adminNote ?? 'ยังไม่มีหมายเหตุจากผู้ดูแล',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(DateTime t) =>
      '${t.day}/${t.month}/${t.year + 543} เวลา ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        SizedBox(width: 70, child: Text(label)),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.detail,
    this.done = false,
    this.current = false,
    this.last = false,
  });
  final String title;
  final String detail;
  final bool done;
  final bool current;
  final bool last;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = done
        ? const Color(0xFF248568)
        : current
        ? const Color(0xFF4D8DFF)
        : theme.colorScheme.outline;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || current ? color : null,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done || current
                      ? Icon(
                          done ? Icons.check_rounded : Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 19,
                        )
                      : null,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: color.withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
