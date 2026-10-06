import 'package:domcareapp/services/auth_service.dart';
import 'package:domcareapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'test_auth_service.dart';

class RequestTestApi extends TestAuthService {
  RequestTestApi({bool empty = false}) {
    if (!empty) {
      for (final entry in [
        (1, 'แอร์ไม่เย็น', 'in_progress'),
        (2, 'ก๊อกน้ำรั่ว', 'completed'),
        (3, 'หลอดไฟเสีย', 'pending'),
      ]) {
        requests.add(row(entry.$1, entry.$2, entry.$3));
      }
    }
  }
  static Map<String, dynamic> row(int id, String title, String status) => {
    'id': id,
    'title': title,
    'status': status,
    'category': 'repair',
    'description': 'รายละเอียดปัญหาทดสอบ',
    'room': 'T01',
    'resident_name': 'ผู้พักจากฐานข้อมูล',
    'created_at': '2026-09-22T03:00:00Z',
  };
  final requests = <Map<String, dynamic>>[];
  final history = <int, List<Map<String, dynamic>>>{};
  final calls = <String>[];
  Map<String, dynamic>? lastCreate;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> authorizedRequest(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    calls.add('$method $path');
    if (fail) throw const AuthException('ทดสอบการเชื่อมต่อล้มเหลว');
    if (path == '/api/residents') return {'users': <dynamic>[]};
    if (method == 'POST') {
      lastCreate = body;
      final request = row(
        requests.length + 1,
        body!['title'] as String,
        'pending',
      )..addAll(body);
      requests.insert(0, request);
      return {'request': request};
    }
    final uri = Uri.parse(path);
    if (uri.path == '/api/requests') {
      return {
        'requests': uri.queryParameters['limit'] == '3'
            ? requests.take(3).toList()
            : requests.toList(),
        'counts': {
          'total': requests.length,
          for (final status in ['pending', 'in_progress', 'completed'])
            status: requests.where((r) => r['status'] == status).length,
        },
      };
    }
    final id = int.parse(uri.pathSegments.last);
    final request = requests.firstWhere((r) => r['id'] == id);
    final entries = history.putIfAbsent(id, () => []);
    if (method == 'PATCH') {
      final from = request['status'];
      if (body!['action'] == 'edit') {
        request.addAll({
          'title': body['title'],
          'description': body['description'],
          'category': body['category'],
        });
      } else {
        request['status'] = body['action'] == 'cancel'
            ? 'cancelled'
            : body['status'];
      }
      entries.add({
        'from_status': from,
        'to_status': request['status'],
        'note': body['note'] ?? 'แก้ไขรายละเอียดคำร้อง',
        'actor_name': 'ผู้ดำเนินการ',
        'created_at': '2026-09-22T04:00:00Z',
      });
      return {'status': 'ok'};
    }
    return {
      'request': Map<String, dynamic>.from(request),
      'history': entries.toList(),
    };
  }
}

Future<Widget> requestTestApp(
  Widget page, {
  bool dark = false,
  bool admin = false,
  RequestTestApi? api,
}) async {
  final session = AuthSession(api ?? RequestTestApi());
  await session.login(admin ? 'admin' : 'resident', 'password');
  return AuthScope(
    session: session,
    child: MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(body: page),
    ),
  );
}
