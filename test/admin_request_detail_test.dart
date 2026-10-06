import 'package:domcareapp/screens/admin/admin_requests_page.dart';
import 'package:domcareapp/screens/live_request_detail_page.dart';
import 'helpers/request_test_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Admin API transitions retain history and update filter $dark',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = RequestTestApi(empty: true);
        api.requests.add(RequestTestApi.row(1, 'แอร์ไม่เย็น', 'pending'));
        await tester.pumpWidget(
          await requestTestApp(
            const AdminRequestsPage(),
            dark: dark,
            admin: true,
            api: api,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('แอร์ไม่เย็น'));
        await tester.pumpAndSettle();
        expect(find.byType(LiveRequestDetailPage), findsOneWidget);
        final save = find.widgetWithText(FilledButton, 'บันทึกสถานะ');
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('กรุณากรอกหมายเหตุ'), findsOneWidget);
        for (final status in ['กำลังตรวจสอบ/ซ่อม', 'เสร็จสิ้น']) {
          await tester.ensureVisible(find.byType(TextFormField));
          await tester.enterText(
            find.byType(TextFormField),
            'หมายเหตุ $status',
          );
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.widgetWithText(FilledButton, 'บันทึกสถานะ'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('หมายเหตุ เสร็จสิ้น'),
          250,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('หมายเหตุ กำลังตรวจสอบ/ซ่อม'), findsOneWidget);
        expect(find.text('หมายเหตุ เสร็จสิ้น'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        final filter = find.byKey(const ValueKey('admin-status-filter-0'));
        await tester.tap(filter);
        await tester.pumpAndSettle();
        await tester.tap(find.text('รอดำเนินการ').last);
        await tester.pumpAndSettle();
        expect(find.text('แอร์ไม่เย็น'), findsNothing);
        expect(find.text('ไม่มีคำร้องในสถานะนี้'), findsOneWidget);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        await tester.tap(find.text('เสร็จสิ้น').last);
        await tester.pumpAndSettle();
        expect(find.text('แอร์ไม่เย็น'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
