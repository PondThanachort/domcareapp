import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AdminResidentsPage extends StatefulWidget {
  const AdminResidentsPage({super.key});
  @override
  State<AdminResidentsPage> createState() => _AdminResidentsPageState();
}

class _AdminResidentsPageState extends State<AdminResidentsPage> {
  AuthSession? _session;
  List<AuthUser> _users = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.of(context);
    if (_session != session) {
      _session = session;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _session!.service.authorizedRequest(
        'GET',
        '/api/residents',
        _session!.token ?? '',
      );
      final users = (data['users'] as List)
          .map((u) => AuthUser.fromJson(u as Map<String, dynamic>))
          .where((u) => u.role == 'resident')
          .toList();
      if (mounted) setState(() => _users = users);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([AuthUser? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResidentForm(session: _session!, user: user),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(AuthUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบผู้พัก'),
        content: Text(
          'ลบบัญชี ${user.username} ของ ${user.displayName}?\nหากไม่มีประวัติจะลบถาวรและใช้ชื่อผู้ใช้นี้ใหม่ได้ หากมีประวัติจะยกเลิกบัญชีและเก็บไว้ในรายการ',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยันลบ'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _busy = true);
    try {
      final result = await _session!.service.authorizedRequest(
        'DELETE',
        '/api/residents/${user.id}',
        _session!.token ?? '',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'ลบผู้พักแล้ว'),
          ),
        );
        await _load();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'จัดการผู้พัก',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton.filled(
              tooltip: 'เพิ่มผู้พัก',
              onPressed: _busy ? null : () => _edit(),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'บัญชีผู้ใช้และหมายเลขห้อง',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ] else if (_users.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('ยังไม่มีบัญชีผู้พัก')),
          )
        else
          for (final user in _users)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: FittedBox(child: Text(user.room ?? '-')),
                    ),
                  ),
                  title: Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${user.username} · ห้อง ${user.room}'),
                      if (user.isDeleted) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ยกเลิกบัญชีแล้ว',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'เข้าใช้งานไม่ได้ · เก็บบัญชีและชื่อผู้ใช้ไว้ในประวัติ',
                        ),
                      ],
                    ],
                  ),
                  trailing: user.isDeleted
                      ? null
                      : PopupMenuButton<String>(
                          enabled: !_busy,
                          tooltip: 'จัดการ ${user.username}',
                          onSelected: (action) {
                            if (action == 'edit') {
                              _edit(user);
                            } else {
                              _delete(user);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('ลบผู้พัก'),
                            ),
                          ],
                        ),
                ),
              ),
            ),
        if (_busy) const LinearProgressIndicator(),
      ],
    ),
  );
}

class _ResidentForm extends StatefulWidget {
  const _ResidentForm({required this.session, this.user});
  final AuthSession session;
  final AuthUser? user;
  @override
  State<_ResidentForm> createState() => _ResidentFormState();
}

class _ResidentFormState extends State<_ResidentForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.displayName);
  late final _username = TextEditingController(text: widget.user?.username);
  late final _room = TextEditingController(text: widget.user?.room);
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _room.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.session.service.authorizedRequest(
        widget.user == null ? 'POST' : 'PUT',
        '/api/residents${widget.user == null ? '' : '/${widget.user!.id}'}',
        widget.session.token ?? '',
        body: {
          'display_name': _name.text.trim(),
          'username': _username.text.trim(),
          'room': _room.text.trim(),
          if (_password.text.isNotEmpty || widget.user == null)
            'password': _password.text,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.user == null
                            ? 'เพิ่มข้อมูลผู้พัก'
                            : 'แก้ไขข้อมูลผู้พัก',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'ปิด',
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  widget.user == null
                      ? 'สร้างบัญชีผู้ใช้และระบุห้องพัก'
                      : 'อัปเดตข้อมูลบัญชีและห้องพัก',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                if (widget.user != null) ...[
                  _field(_name, 'ชื่อผู้พัก', 100, Icons.person_rounded),
                  const SizedBox(height: 18),
                ],
                _field(
                  _username,
                  'ชื่อผู้ใช้',
                  50,
                  Icons.person_outline_rounded,
                ),
                const SizedBox(height: 18),
                if (widget.user != null) ...[
                  _field(
                    _room,
                    'หมายเลขห้อง',
                    20,
                    Icons.door_front_door_outlined,
                  ),
                  const Divider(height: 36),
                ],
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      widget.user == null ? 'รหัสผ่าน' : 'เปลี่ยนรหัสผ่าน',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (widget.user != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ไม่บังคับ'),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: _hidePassword,
                  textInputAction: widget.user == null
                      ? TextInputAction.next
                      : TextInputAction.done,
                  decoration:
                      _decoration(
                        widget.user == null ? 'รหัสผ่าน' : 'รหัสผ่านใหม่',
                        Icons.lock_outline_rounded,
                      ).copyWith(
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'แสดงรหัสผ่าน'
                              : 'ซ่อนรหัสผ่าน',
                          onPressed: _saving
                              ? null
                              : () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        helperText: widget.user == null
                            ? null
                            : 'เว้นว่างเพื่อใช้รหัสผ่านเดิม',
                      ),
                  validator: (v) {
                    if (widget.user == null &&
                        (v == null || v.trim().isEmpty)) {
                      return 'กรุณากรอกรหัสผ่าน';
                    }
                    if (v != null &&
                        v.isNotEmpty &&
                        (v.trim().isEmpty || utf8.encode(v).length > 72)) {
                      return 'รหัสผ่านต้องไม่เป็นช่องว่างและไม่เกิน 72 ไบต์';
                    }
                    return null;
                  },
                ),
                if (widget.user == null) ...[
                  const SizedBox(height: 18),
                  _field(_name, 'ชื่อผู้พัก', 100, Icons.person_rounded),
                  const SizedBox(height: 18),
                  _field(
                    _room,
                    'หมายเลขห้อง',
                    20,
                    Icons.door_front_door_outlined,
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: FilledButton(
                        key: const ValueKey('resident-save'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(
                          _saving
                              ? 'กำลังบันทึก...'
                              : widget.user == null
                              ? 'เพิ่มผู้พัก'
                              : 'บันทึกการแก้ไข',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    counterText: '',
    fillColor: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF242427)
        : const Color(0xFFF1F1F3),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label,
    int max,
    IconData icon,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLength: max,
        textInputAction: TextInputAction.next,
        decoration: _decoration(label, icon),
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'กรุณากรอก$label' : null,
      ),
    ],
  );
}
