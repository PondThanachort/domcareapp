import 'package:flutter/material.dart';

enum RequestStatus {
  pending('รอดำเนินการ'),
  inProgress('กำลังตรวจสอบ/ซ่อม'),
  completed('เสร็จสิ้น');

  const RequestStatus(this.label);
  final String label;
}

class MockStatusEntry {
  const MockStatusEntry(this.status, this.time, this.actor, this.note);
  final RequestStatus status;
  final DateTime time;
  final String actor;
  final String note;
}

/// In-memory preview only. The backend must enforce permissions and save history.
class MockAdminRequest {
  MockAdminRequest({
    required this.title,
    required this.resident,
    required this.room,
    required this.icon,
    required this.status,
    this.history = const [],
  });
  final String title;
  final String resident;
  final String room;
  final IconData icon;
  RequestStatus status;
  List<MockStatusEntry> history;
}
