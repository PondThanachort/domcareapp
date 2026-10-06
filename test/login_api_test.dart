import 'dart:convert';
import 'package:domcareapp/main.dart';
import 'package:domcareapp/screens/login_page.dart';
import 'package:domcareapp/screens/admin/admin_shell.dart';
import 'package:domcareapp/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'Rejected login stays on login; API role opens admin; logout clears session and stack',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = AuthService(
        client: MockClient((request) async {
          if (request.url.path == '/api/residents') {
            return http.Response('{"users":[]}', 200);
          }
          if (request.url.path == '/api/requests') {
            return http.Response('{"requests":[],"counts":{}}', 200);
          }
          final body = jsonDecode(request.body);
          if (body['password'] != '@admin') return http.Response('{}', 401);
          return http.Response(
            jsonEncode({
              'token': 'test-jwt',
              'user': {
                'id': 1,
                'username': 'admin',
                'display_name': 'Admin DB',
                'room': null,
                'role': 'admin',
              },
            }),
            200,
          );
        }),
      );
      addTearDown(service.dispose);
      await tester.pumpWidget(MyApp(authService: service));
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      final login = find.widgetWithText(FilledButton, 'เข้าสู่ระบบ');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '@admin');
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(find.byType(AdminShell), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('Admin DB'), findsOneWidget);
      final session = AuthScope.of(tester.element(find.byType(AdminShell)));
      expect(session.token, 'test-jwt');
      await tester.tap(find.text('ออกจากระบบ'));
      await tester.pumpAndSettle();
      expect(session.token, isNull);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
