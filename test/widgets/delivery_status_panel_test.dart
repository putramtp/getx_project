import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/delivery_status_model.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/modules/delivery/views/delivery_status_panel.dart';

import 'pump_ui.dart';

void main() {
  final pending = DeliveryStatusModel(id: 1, name: 'Pending', color: '#EFBF04');
  final shipped = DeliveryStatusModel(id: 2, name: 'Shipped', color: '#FFFFFF');
  final cancelled = DeliveryStatusModel(id: 4, name: 'Cancelled', color: '#D2453B');

  Future<void> pump(WidgetTester t, {required void Function(DeliveryStatusModel) onMark, VoidCallback? onEdit}) =>
      pumpUi(
        t,
        Scaffold(
          body: SingleChildScrollView(
            child: deliveryStatusPanel(
              9.6,
              current: pending,
              others: [shipped, cancelled],
              onMark: onMark,
              onEdit: onEdit ?? () {},
            ),
          ),
        ),
      );

  testWidgets('shows the current status and one Mark button per other status', (tester) async {
    await pump(tester, onMark: (_) {});
    expect(find.text('Update status'), findsOneWidget);
    expect(find.text('Now: Pending'), findsOneWidget);
    expect(find.text('Mark Shipped'), findsOneWidget);
    expect(find.text('Mark Cancelled'), findsOneWidget);
    expect(find.text('Mark Pending'), findsNothing);
    expect(find.text('Edit details'), findsOneWidget);
  });

  testWidgets('statuses read as the web labels them', (tester) async {
    await pumpUi(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: deliveryStatusPanel(
            9.6,
            current: DeliveryStatusModel(id: 1, name: 'Pending', label: 'Scheduled', color: ''),
            others: [DeliveryStatusModel(id: 2, name: 'Shipped', label: 'On the way', color: '')],
            onMark: (_) {},
            onEdit: () {},
            undoTo: 'Scheduled',
            onUndo: () {},
          ),
        ),
      ),
    );
    expect(find.text('Now: Scheduled'), findsOneWidget);
    expect(find.text('Mark On the way'), findsOneWidget);
    expect(find.text('Mark Shipped'), findsNothing);
  });

  testWidgets('white API color falls back to navy', (tester) async {
    await pump(tester, onMark: (_) {});
    expect(tester.widget<Text>(find.text('Mark Shipped')).style?.color, navyMid);
  });

  testWidgets('tapping Mark and Edit calls back', (tester) async {
    DeliveryStatusModel? marked;
    var edited = false;
    await pump(tester, onMark: (s) => marked = s, onEdit: () => edited = true);
    await tester.tap(find.text('Mark Shipped'));
    await tester.tap(find.text('Edit details'));
    expect(marked?.id, 2);
    expect(edited, isTrue);
  });
}
