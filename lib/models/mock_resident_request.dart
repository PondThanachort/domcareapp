import 'package:flutter/material.dart';

class ResidentHistoryEntry {
  ResidentHistoryEntry(
    this.title,
    this.note, {
    DateTime? time,
    this.actor = 'สมชาย ใจดี',
  }) : time = time ?? DateTime.now();
  final String title, note, actor;
  final DateTime time;
}

/// Local preview data; ownership and status must also be checked by the API.
class MockResidentRequest {
  MockResidentRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.icon,
    required this.color,
    this.adminNote,
  });
  static const categories = [
    'แจ้งซ่อม',
    'แจ้งทำความสะอาด',
    'แจ้งย้ายออก',
    'แจ้งอื่น ๆ/ฉุกเฉิน',
  ];
  static const labels = {
    'pending': 'รอดำเนินการ',
    'in_progress': 'กำลังตรวจสอบ/ซ่อม',
    'completed': 'เสร็จสิ้น',
    'cancelled': 'ยกเลิก',
  };
  final String id, date;
  String title, description, status;
  String category = 'แจ้งซ่อม';
  final IconData icon;
  final Color color;
  final String? adminNote;
  String? cancellationReason;
  final history = <ResidentHistoryEntry>[];
  bool get canEdit => status == 'pending';

  bool edit(String category, String title, String description) {
    if (!canEdit ||
        !categories.contains(category) ||
        title.trim().isEmpty ||
        description.trim().isEmpty) {
      return false;
    }
    this.category = category;
    this.title = title.trim();
    this.description = description.trim();
    history.add(
      ResidentHistoryEntry(
        'แก้ไขคำร้อง',
        'ปรับปรุงหมวดหมู่ หัวข้อ และรายละเอียด',
      ),
    );
    return true;
  }

  bool cancel(String reason) {
    if (!canEdit || reason.trim().isEmpty) return false;
    cancellationReason = reason.trim();
    status = 'cancelled';
    history.add(ResidentHistoryEntry('ยกเลิก', cancellationReason!));
    return true;
  }
}
