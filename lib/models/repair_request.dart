import 'package:flutter/material.dart';

class RepairRequest {
  RepairRequest.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = json['title'] as String,
      description = json['description'] as String,
      category = json['category'] as String,
      status = json['status'] as String,
      room = json['room'] as String,
      resident = json['resident_name'] as String,
      createdAt = DateTime.parse(json['created_at'] as String).toLocal();

  final int id;
  final String title, description, category, status, room, resident;
  final DateTime createdAt;
  static const categories = {
    'repair': 'แจ้งซ่อม',
    'cleaning': 'แจ้งทำความสะอาด',
    'move_out': 'แจ้งย้ายออก',
    'other_emergency': 'แจ้งอื่น ๆ/ฉุกเฉิน',
  };
  static const statuses = {
    'pending': 'รอดำเนินการ',
    'in_progress': 'กำลังตรวจสอบ/ซ่อม',
    'completed': 'เสร็จสิ้น',
    'cancelled': 'ยกเลิก',
  };
  String get code => '#REQ-${id.toString().padLeft(6, '0')}';
  String get date => formatDate(createdAt);
  static String formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year + 543} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  Color get color => switch (status) {
    'pending' => const Color(0xFFB87910),
    'in_progress' => const Color(0xFF6A75FF),
    'completed' => const Color(0xFF248568),
    _ => const Color(0xFFC62828),
  };
  IconData get icon => switch (category) {
    'cleaning' => Icons.cleaning_services_rounded,
    'move_out' => Icons.move_up_rounded,
    'other_emergency' => Icons.warning_amber_rounded,
    _ => Icons.home_repair_service_rounded,
  };
}
