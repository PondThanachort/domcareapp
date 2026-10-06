import 'package:flutter/material.dart';
import '../models/repair_request.dart';
import '../services/auth_service.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  int? _selectedCategory;
  bool _submitting = false;

  static const _categories = [
    (Icons.home_repair_service_rounded, 'แจ้งซ่อม', Color(0xFF28795F)),
    (Icons.cleaning_services_rounded, 'แจ้งทำความสะอาด', Color(0xFF3B82F6)),
    (Icons.move_up_rounded, 'แจ้งย้ายออก', Color(0xFFF59E0B)),
    (Icons.warning_amber_rounded, 'แจ้งอื่น ๆ/ฉุกเฉิน', Color(0xFFDC4C4C)),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกหมวดหมู่ปัญหา')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final session = AuthScope.of(context);
    try {
      await session.service.authorizedRequest(
        'POST',
        '/api/requests',
        session.token!,
        body: {
          'category': RepairRequest.categories.keys.elementAt(
            _selectedCategory!,
          ),
          'title': _titleController.text.trim(),
          'description': _detailController.text.trim(),
        },
      );
      session.requestsChanged();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF248A68)),
        title: const Text('ส่งคำร้องแล้ว'),
        content: const Text(
          'คำร้องของคุณอยู่ในสถานะรอดำเนินการ\nสามารถติดตามได้ที่หน้าคำร้อง',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? const Color(0xFF9B9BA1) : const Color(0xFF77777E);

    return Scaffold(
      appBar: AppBar(
        title: const Text('แจ้งปัญหาใหม่'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Text(
                'เลือกหมวดหมู่',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = _selectedCategory == index;
                  return InkWell(
                    onTap: () => setState(() => _selectedCategory = index),
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected
                            ? category.$3.withValues(alpha: dark ? 0.20 : 0.10)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected ? category.$3 : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category.$1, color: category.$3, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            category.$2,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 26),
              Text(
                'หัวข้อปัญหา',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                maxLength: 200,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'เช่น แอร์ไม่เย็น'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรุณากรอกหัวข้อปัญหา'
                    : null,
              ),
              const SizedBox(height: 22),
              Text(
                'รายละเอียด',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _detailController,
                maxLength: 2000,
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'อธิบายปัญหาเพิ่มเติม...',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรุณากรอกรายละเอียดปัญหา'
                    : null,
              ),
              const SizedBox(height: 22),
              Text(
                'รูปภาพ (ไม่บังคับ)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ระบบแนบรูปภาพจะเพิ่มในขั้นตอนถัดไป'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 92,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dark
                          ? const Color(0xFF333337)
                          : const Color(0xFFDADADF),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'เพิ่มรูปภาพ',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: dark
                      ? Colors.white
                      : const Color.fromARGB(255, 3, 3, 3),
                  foregroundColor: dark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text(
                        'ส่งคำร้องแจ้งซ่อม',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
