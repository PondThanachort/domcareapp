import 'package:domcareapp/screens/requests_page.dart';
import 'package:domcareapp/screens/live_request_detail_page.dart';
import 'helpers/request_test_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Resident filters API data and opens details (dark: $dark)', (
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
      expect(find.text('แอร์ไม่เย็น'), findsOneWidget);
      expect(find.text('ก๊อกน้ำรั่ว'), findsOneWidget);
      expect(find.text('หลอดไฟเสีย'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('pending')));
      await tester.tap(find.byKey(const ValueKey('pending')));
      await tester.pumpAndSettle();
      expect(find.text('หลอดไฟเสีย'), findsOneWidget);
      expect(find.text('แอร์ไม่เย็น'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('in_progress')));
      await tester.tap(find.byKey(const ValueKey('in_progress')));
      await tester.pumpAndSettle();
      expect(find.text('หลอดไฟเสีย'), findsNothing);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(LiveRequestDetailPage), findsOneWidget);
      expect(find.text('แอร์ไม่เย็น'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('ประวัติการดำเนินการ'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('ประวัติการดำเนินการ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('แอร์ไม่เย็น'), findsOneWidget);
      final completed = find.byKey(const ValueKey('completed'));
      await tester.ensureVisible(completed);
      await tester.tap(completed);
      await tester.pumpAndSettle();
      expect(find.text('ก๊อกน้ำรั่ว'), findsOneWidget);
      expect(find.text('แอร์ไม่เย็น'), findsNothing);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      final all = find.byKey(const ValueKey('all'));
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(find.text('แอร์ไม่เย็น'), findsOneWidget);
      expect(find.text('ก๊อกน้ำรั่ว'), findsOneWidget);
      expect(find.text('หลอดไฟเสีย'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
