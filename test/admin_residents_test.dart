import 'package:domcareapp/services/auth_service.dart';
import 'package:domcareapp/screens/admin/admin_residents_page.dart';
import 'package:domcareapp/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ResidentTestApi extends AuthService {
  List<Map<String, dynamic>> users = [];
  final calls = <String>[];
  @override
  Future<AuthResult> login(String username, String password) async =>
      const AuthResult(
        'token',
        AuthUser(id: 1, username: 'admin', displayName: 'Admin', role: 'admin'),
      );
  @override
  Future<Map<String, dynamic>> authorizedRequest(
    String method,
    String path,
    String token, {
    Map<String, dynamic>? body,
  }) async {
    calls.add(method);
    if (method == 'POST') users.add({...body!, 'id': 2, 'role': 'resident'});
    if (method == 'PUT') users[0] = {...users[0], ...body!};
    if (method == 'DELETE') users.clear();
    return {'users': users};
  }
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Archived residents remain visible without edit/delete actions $dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = ResidentTestApi();
        api.users = [
          {
            'id': 9,
            'username': 'archived',
            'display_name': 'ผู้พักเก่า',
            'room': '305',
            'role': 'resident',
            'deleted_at': '2026-09-21T00:00:00Z',
          },
        ];
        final session = AuthSession(api);
        await session.login('admin', 'pass');
        addTearDown(session.dispose);
        addTearDown(api.dispose);
        await tester.pumpWidget(
          AuthScope(
            session: session,
            child: MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: const Scaffold(body: AdminResidentsPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ผู้พักเก่า'), findsOneWidget);
        expect(find.text('ยกเลิกบัญชีแล้ว'), findsOneWidget);
        expect(find.byType(PopupMenuButton<String>), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('Resident list add edit cancel-delete confirm-delete $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ResidentTestApi();
      final session = AuthSession(api);
      await session.login('admin', 'pass');
      addTearDown(session.dispose);
      addTearDown(api.dispose);
      await tester.pumpWidget(
        AuthScope(
          session: session,
          child: MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: const Scaffold(body: AdminResidentsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีบัญชีผู้พัก'), findsOneWidget);
      await tester.tap(find.byTooltip('เพิ่มผู้พัก'));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('resident-save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('กรุณากรอกชื่อผู้พัก'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newresident');
      await tester.enterText(fields.at(1), 'pass123');
      await tester.enterText(fields.at(2), 'ผู้พักใหม่');
      await tester.enterText(fields.at(3), '202');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('แสดงรหัสผ่าน'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('แสดงรหัสผ่าน'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller!.text,
        'pass123',
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(544));
      await tester.tap(save);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('ผู้พักใหม่'), findsOneWidget);
      await tester.tap(find.byTooltip('จัดการ newresident'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แก้ไข'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(fields.at(3)).controller!.text, '');
      await tester.enterText(fields.at(0), 'ชื่อใหม่');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(544));
      await tester.tap(save);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('ชื่อใหม่'), findsOneWidget);
      await tester.tap(find.byTooltip('จัดการ newresident'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบผู้พัก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(api.calls.contains('DELETE'), isFalse);
      await tester.tap(find.byTooltip('จัดการ newresident'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ลบผู้พัก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันลบ'));
      await tester.pumpAndSettle();
      expect(find.text('ยังไม่มีบัญชีผู้พัก'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
