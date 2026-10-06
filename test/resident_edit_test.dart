import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:domcareapp/screens/requests_page.dart';
import 'helpers/request_test_api.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Edit and cancel pending request retains history $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        await requestTestApp(const RequestsPage(), dark: dark),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('หลอดไฟเสีย'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'แก้ไขคำร้อง'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'แก้ไขคำร้อง'));
      await tester.pumpAndSettle();
      final title = find.byKey(const ValueKey('edit-title'));
      expect(
        tester.widget<TextFormField>(title).controller!.text,
        'หลอดไฟเสีย',
      );
      await tester.enterText(title, '   ');
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();
      expect(find.text('กรุณากรอกหัวข้อ'), findsOneWidget);
      await tester.enterText(title, 'ไฟห้องน้ำเสีย');
      await tester.enterText(
        find.byKey(const ValueKey('edit-description')),
        'เปิดสวิตช์แล้วไฟไม่ติด',
      );
      await tester.tap(find.text('บันทึกการแก้ไข'));
      await tester.pumpAndSettle();
      expect(find.text('ไฟห้องน้ำเสีย'), findsOneWidget);
      await tester.ensureVisible(find.text('ยกเลิกคำร้อง'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิกคำร้อง'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('กรุณากรอกเหตุผลการยกเลิก'), findsOneWidget);
      await tester.tap(find.text('กลับ'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'แก้ไขคำร้อง'), findsOneWidget);
      await tester.tap(find.text('ยกเลิกคำร้อง'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'เปลี่ยนหลอดไฟเองแล้ว',
      );
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'แก้ไขคำร้อง'), findsNothing);
      expect(find.text('ยกเลิกคำร้อง'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('เปลี่ยนหลอดไฟเองแล้ว'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('เปลี่ยนหลอดไฟเองแล้ว'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('ไฟห้องน้ำเสีย'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsWidgets);
      await tester.ensureVisible(find.byKey(const ValueKey('pending')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pending')));
      await tester.pumpAndSettle();
      expect(find.text('ไฟห้องน้ำเสีย'), findsNothing);
      expect(find.text('ไม่มีคำร้องในสถานะนี้'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
