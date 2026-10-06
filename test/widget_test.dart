import 'helpers/test_auth_service.dart';
import 'package:domcareapp/main.dart';
import 'package:domcareapp/screens/login_page.dart';
import 'package:domcareapp/screens/app_shell.dart';
import 'package:domcareapp/screens/create_request_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Login lays out on a phone, validates and opens the shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MyApp(authService: TestAuthService()));
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    final button = find.widgetWithText(FilledButton, 'เข้าสู่ระบบ');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกชื่อผู้ใช้และรหัสผ่าน'), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'demo');
    await tester.enterText(find.byType(TextField).last, 'demo');
    await tester.tap(find.byIcon(CupertinoIcons.eye_slash));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).obscureText,
      isFalse,
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.person_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('เปลี่ยน Light / Dark mode'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('New repair request opens from Home and validates the form', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MyApp(authService: TestAuthService()));
    await tester.enterText(find.byType(TextField).first, 'demo');
    await tester.enterText(find.byType(TextField).last, 'demo');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('แจ้งปัญหาใหม่'));
    await tester.pumpAndSettle();
    expect(find.byType(CreateRequestPage), findsOneWidget);
    expect(find.text('เลือกหมวดหมู่'), findsOneWidget);
    expect(find.text('แจ้งซ่อม'), findsOneWidget);
    expect(find.text('แจ้งทำความสะอาด'), findsOneWidget);
    expect(find.text('แจ้งย้ายออก'), findsOneWidget);
    expect(find.text('แจ้งอื่น ๆ/ฉุกเฉิน'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('ส่งคำร้องแจ้งซ่อม'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -100));
    await tester.pumpAndSettle();
    final submitButton = find.widgetWithText(FilledButton, 'ส่งคำร้องแจ้งซ่อม');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(find.text('กรุณาเลือกหมวดหมู่ปัญหา'), findsOneWidget);
  });
}
