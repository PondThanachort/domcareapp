import 'package:flutter/material.dart';
import '../../models/mock_admin_request.dart';

class AdminRequestDetailPage extends StatefulWidget {
  const AdminRequestDetailPage({super.key, required this.request});
  final MockAdminRequest request;
  @override
  State<AdminRequestDetailPage> createState() => _AdminRequestDetailPageState();
}

class _AdminRequestDetailPageState extends State<AdminRequestDetailPage> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  RequestStatus? _selected;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  RequestStatus? get _next => switch (widget.request.status) {
    RequestStatus.pending => RequestStatus.inProgress,
    RequestStatus.inProgress => RequestStatus.completed,
    RequestStatus.completed => null,
  };

  String _date(DateTime time) =>
      '${time.day}/${time.month}/${time.year + 543} เวลา ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _save() {
    if (!_form.currentState!.validate() ||
        _selected != _next ||
        _next == null) {
      return;
    }
    setState(() {
      widget.request.status = _selected!;
      widget.request.history = [
        ...widget.request.history,
        MockStatusEntry(
          _selected!,
          DateTime.now(),
          'ผู้ดูแลระบบ (admin)',
          _note.text.trim(),
        ),
      ];
      _selected = null;
      _note.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกสถานะตัวอย่างแล้ว')));
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
          _section(context, [
            Text('#REQ-202609-0012', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  child: Icon(request.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(request.title, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(request.status.label),
              avatar: const Icon(Icons.schedule_rounded, size: 18),
            ),
            const Divider(height: 28),
            Text(
              'ผู้พัก · ${request.resident}',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'ห้อง ${request.room}  ·  หมวดหมู่ แจ้งซ่อม',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'แจ้งเมื่อ ${_date(request.history.first.time)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text('รายละเอียดปัญหา', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'เปิดแอร์แล้วมีแต่ลม แต่ไม่มีความเย็น แม้ปรับอุณหภูมิลงแล้ว อาการยังเหมือนเดิม',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            const Text('ไม่มีรูปภาพแนบในข้อมูลตัวอย่างนี้'),
          ]),
          const SizedBox(height: 16),
          _section(context, [
            Text('อัปเดตสถานะคำร้อง', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'ผู้ดูแลติดต่อช่างนอกระบบ แล้วบันทึกความคืบหน้าที่นี่',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            if (_next == null)
              const Text(
                'คำร้องนี้เสร็จสิ้นแล้ว',
                style: TextStyle(fontWeight: FontWeight.w700),
              )
            else
              Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<RequestStatus>(
                      key: ValueKey(request.status),
                      initialValue: _selected,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'สถานะใหม่'),
                      items: [
                        DropdownMenuItem(
                          value: _next,
                          child: Text(_next!.label),
                        ),
                      ],
                      onChanged: (value) => setState(() => _selected = value),
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกสถานะใหม่' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _note,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'หมายเหตุผู้ดูแล',
                        hintText: 'ระบุความคืบหน้าหรือผลการดำเนินการ',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'กรุณากรอกหมายเหตุ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('บันทึกสถานะ'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'ข้อมูล Mock · การเปลี่ยนแปลงเก็บชั่วคราวในหน้านี้',
              style: theme.textTheme.bodySmall,
            ),
          ]),
          const SizedBox(height: 16),
          _section(context, [
            Text('ประวัติการดำเนินการ', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final entry in request.history)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.status.label,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _date(entry.time),
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(entry.actor, style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(entry.note, style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}
