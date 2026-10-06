import 'package:domcareapp/main.dart';
import 'package:domcareapp/screens/admin/admin_shell.dart';
import 'package:domcareapp/screens/create_request_page.dart';
import 'package:domcareapp/screens/requests_page.dart';
import 'package:domcareapp/widgets/request_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/request_test_api.dart';

void main() {
  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'Submission failure keeps form; successful retry updates resident list',
    (tester) async {
      phone(tester);
      final api = RequestTestApi(empty: true);
      await tester.pumpWidget(MyApp(authService: api));
      await tester.enterText(find.byType(TextField).first, 'resident');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แจ้งปัญหาใหม่'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('แจ้งทำความสะอาด'));
      await tester.enterText(
        find.byType(TextFormField).first,
        'ทำความสะอาดห้อง',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'ขอทำความสะอาดพื้นห้อง',
      );
      final submit = find.widgetWithText(FilledButton, 'ส่งคำร้องแจ้งซ่อม');
      await tester.scrollUntilVisible(
        submit,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      api.fail = true;
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.byType(CreateRequestPage), findsOneWidget);
      expect(find.text('ทดสอบการเชื่อมต่อล้มเหลว'), findsOneWidget);
      expect(api.requests, isEmpty);
      api.fail = false;
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('ส่งคำร้องแล้ว'), findsOneWidget);
      expect(api.lastCreate, {
        'category': 'cleaning',
        'title': 'ทำความสะอาดห้อง',
        'description': 'ขอทำความสะอาดพื้นห้อง',
      });
      await tester.tap(find.text('ตกลง'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.receipt_long_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('ทำความสะอาดห้อง'), findsOneWidget);
      expect(find.textContaining('ห้อง T01'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'Dashboard shows latest 3; view all resets filter and switches tab $dark',
      (tester) async {
        phone(tester);
        final api = RequestTestApi(empty: true);
        for (var i = 4; i > 0; i--) {
          api.requests.add(RequestTestApi.row(i, 'คำร้องที่ $i', 'pending'));
        }
        await tester.pumpWidget(
          await requestTestApp(
            AdminShell(onToggleTheme: () {}),
            admin: true,
            dark: dark,
            api: api,
          ),
        );
        await tester.pumpAndSettle();
        expect(api.calls, contains('GET /api/requests?limit=3'));
        expect(find.byType(RequestCard), findsNWidgets(3));
        expect(find.text('คำร้องที่ 1'), findsNothing);
        await tester.tap(find.text('ดูทั้งหมด'));
        await tester.pumpAndSettle();
        expect(find.byType(RequestCard), findsNWidgets(4));
        expect(find.text('คำร้องที่ 1'), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('เสร็จสิ้น').last);
        await tester.pumpAndSettle();
        expect(find.byType(RequestCard), findsNothing);
        await tester.tap(find.byIcon(Icons.dashboard_rounded).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('ดูทั้งหมด'));
        await tester.pumpAndSettle();
        expect(find.byType(RequestCard), findsNWidgets(4));
        expect(find.text('ทั้งหมด'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('List error offers retry and shows empty state', (tester) async {
    final api = RequestTestApi(empty: true)..fail = true;
    await tester.pumpWidget(
      await requestTestApp(const RequestsPage(), api: api),
    );
    await tester.pumpAndSettle();
    expect(find.text('ทดสอบการเชื่อมต่อล้มเหลว'), findsOneWidget);
    api.fail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pumpAndSettle();
    expect(find.text('ไม่มีคำร้องในสถานะนี้'), findsOneWidget);
    expect(find.byType(RequestCard), findsNothing);
  });
}
