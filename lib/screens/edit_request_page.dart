import 'package:flutter/material.dart';
import '../models/mock_resident_request.dart';

class EditRequestPage extends StatefulWidget {
  const EditRequestPage({super.key, required this.request});
  final MockResidentRequest request;
  @override
  State<EditRequestPage> createState() => _EditRequestPageState();
}

class _EditRequestPageState extends State<EditRequestPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.request.title);
  late final _description = TextEditingController(
    text: widget.request.description,
  );
  late String _category = widget.request.category;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('แก้ไขคำร้อง'), centerTitle: true),
    body: SafeArea(
      top: false,
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('แก้ไขได้เฉพาะคำร้องที่รอดำเนินการ'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
              items: MockResidentRequest.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: widget.request.canEdit
                  ? (value) => setState(() => _category = value!)
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('edit-title'),
              controller: _title,
              readOnly: !widget.request.canEdit,
              decoration: const InputDecoration(labelText: 'หัวข้อ'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกหัวข้อ'
                  : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('edit-description'),
              controller: _description,
              minLines: 4,
              maxLines: 6,
              readOnly: !widget.request.canEdit,
              decoration: const InputDecoration(labelText: 'รายละเอียด'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'กรุณากรอกรายละเอียด'
                  : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: !widget.request.canEdit
                  ? null
                  : () {
                      if (!_form.currentState!.validate()) return;
                      if (widget.request.edit(
                        _category,
                        _title.text,
                        _description.text,
                      )) {
                        Navigator.pop(context, true);
                      }
                    },
              child: const Text('บันทึกการแก้ไข'),
            ),
          ],
        ),
      ),
    ),
  );
}

class CancelRequestDialog extends StatefulWidget {
  const CancelRequestDialog({super.key});
  @override
  State<CancelRequestDialog> createState() => _CancelRequestDialogState();
}

class _CancelRequestDialogState extends State<CancelRequestDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ยกเลิกคำร้อง'),
    scrollable: true,
    content: Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'คำร้องจะยังอยู่ในประวัติ และจะไม่สามารถแก้ไขได้หลังยกเลิก',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reason,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'เหตุผลการยกเลิก'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'กรุณากรอกเหตุผลการยกเลิก'
                : null,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('กลับ'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const Text('ยืนยันยกเลิก'),
      ),
    ],
  );
}
