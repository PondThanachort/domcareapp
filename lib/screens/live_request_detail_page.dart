import 'package:flutter/material.dart';
import '../models/repair_request.dart';
import '../services/auth_service.dart';
import 'edit_request_page.dart' show CancelRequestDialog;

class LiveRequestDetailPage extends StatefulWidget {
  const LiveRequestDetailPage({super.key, required this.id});
  final int id;
  @override
  State<LiveRequestDetailPage> createState() => _LiveRequestDetailPageState();
}

class _LiveRequestDetailPageState extends State<LiveRequestDetailPage> {
  AuthSession? _session;
  RepairRequest? _request;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true, _saving = false;
  String? _error;
  final _note = TextEditingController();
  final _statusForm = GlobalKey<FormState>();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_session == null) {
      _session = AuthScope.of(context);
      _load();
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _session!.service.authorizedRequest(
        'GET',
        '/api/requests/${widget.id}',
        _session!.token!,
      );
      final request = RepairRequest.fromJson(
        data['request'] as Map<String, dynamic>,
      );
      final history = (data['history'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _request = request;
        _history = history;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is AuthException
              ? error.message
              : 'ไม่สามารถอ่านรายละเอียดได้',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(Map<String, dynamic> body) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _session!.service.authorizedRequest(
        'PATCH',
        '/api/requests/${widget.id}',
        _session!.token!,
        body: body,
      );
      _session!.requestsChanged();
      _note.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกคำร้องแล้ว')));
      await _load();
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _EditLiveRequestPage(request: _request!),
      ),
    );
    if (result != null && mounted) {
      await _load();
    }
  }

  Future<void> _cancel() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const CancelRequestDialog(),
    );
    if (reason != null && mounted) {
      await _save({'action': 'cancel', 'note': reason});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final request = _request;
    final admin = _session?.user?.role == 'admin';
    final next = request?.status == 'pending' ? 'in_progress' : 'completed';
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดคำร้อง'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('ลองใหม่')),
            ],
            if (!_loading && _error == null && request != null) ...[
              _section(
                children: [
                  Text(request.code, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 14),
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(RepairRequest.statuses[request.status]!),
                      backgroundColor: request.color.withValues(alpha: .12),
                      labelStyle: TextStyle(color: request.color),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'หมวดหมู่: ${RepairRequest.categories[request.category]}',
                  ),
                  Text('ผู้พัก: ${request.resident}'),
                  Text('ห้อง: ${request.room}'),
                  Text('วันที่แจ้ง: ${request.date}'),
                  const Divider(height: 32),
                  Text('รายละเอียด', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(request.description),
                ],
              ),
              if (!admin && request.status == 'pending') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('แก้ไขคำร้อง'),
                ),
                TextButton(
                  onPressed: _saving ? null : _cancel,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('ยกเลิกคำร้อง'),
                ),
              ],
              if (admin &&
                  ['pending', 'in_progress'].contains(request.status)) ...[
                const SizedBox(height: 20),
                _section(
                  children: [
                    Text(
                      'อัปเดตสถานะคำร้อง',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('สถานะถัดไป: ${RepairRequest.statuses[next]}'),
                    const SizedBox(height: 16),
                    Form(
                      key: _statusForm,
                      child: TextFormField(
                        controller: _note,
                        maxLength: 2000,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'หมายเหตุจากผู้ดูแล',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'กรุณากรอกหมายเหตุ'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () {
                              if (_statusForm.currentState!.validate()) {
                                _save({
                                  'action': 'status',
                                  'status': next,
                                  'note': _note.text.trim(),
                                });
                              }
                            },
                      child: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกสถานะ'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              _section(
                children: [
                  Text(
                    'ประวัติการดำเนินการ',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  for (final entry in _history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            entry['to_status'] == 'cancelled'
                                ? Icons.cancel_outlined
                                : Icons.check_circle_outline,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry['from_status'] == entry['to_status']
                                      ? 'แก้ไขคำร้อง'
                                      : RepairRequest
                                                .statuses[entry['to_status']] ??
                                            '',
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(entry['note'] as String? ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry['actor_name']} · ${RepairRequest.formatDate(DateTime.parse(entry['created_at'] as String).toLocal())}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section({required List<Widget> children}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _EditLiveRequestPage extends StatefulWidget {
  const _EditLiveRequestPage({required this.request});
  final RepairRequest request;
  @override
  State<_EditLiveRequestPage> createState() => _EditLiveRequestPageState();
}

class _EditLiveRequestPageState extends State<_EditLiveRequestPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.request.title);
  late final _description = TextEditingController(
    text: widget.request.description,
  );
  late String _category = widget.request.category;
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final session = AuthScope.of(context);
    final body = {
      'action': 'edit',
      'category': _category,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
    };
    setState(() => _saving = true);
    try {
      await session.service.authorizedRequest(
        'PATCH',
        '/api/requests/${widget.request.id}',
        session.token!,
        body: body,
      );
      session.requestsChanged();
      if (mounted) Navigator.pop(context, body);
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แก้ไขคำร้อง')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'หมวดหมู่'),
            items: RepairRequest.categories.entries
                .map(
                  (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _category = value!),
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('edit-title'),
            controller: _title,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'หัวข้อ'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'กรุณากรอกหัวข้อ' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            key: const ValueKey('edit-description'),
            controller: _description,
            maxLength: 2000,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'รายละเอียด'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'กรุณากรอกรายละเอียด' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข'),
          ),
        ],
      ),
    ),
  );
}
