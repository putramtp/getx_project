import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/widget/order_list_widgets.dart';

void main() {
  Future<Future<bool?>> openDialog(WidgetTester tester, List<SubmitConfirmLine> lines) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final result = Get.dialog<bool>(orderSubmitConfirmDialog(
      size: 10,
      accent: AppAccent.amber,
      title: const Text('Continue to Outflowing Items?'),
      summary: 'Total Outflowing quantity: 3',
      lines: lines,
    ));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows only the lines being submitted, with their entries', (tester) async {
    await openDialog(tester, const [
      SubmitConfirmLine(name: 'Sensor PT100', entries: ['SKU-0001'], total: 1),
      SubmitConfirmLine(name: 'Gear Oil', entries: ['Filled: 2']),
    ]);

    expect(find.text('Sensor PT100'), findsOneWidget);
    expect(find.text('SKU-0001'), findsOneWidget);
    expect(find.text('Total: 1'), findsOneWidget);
    expect(find.text('Filled: 2'), findsOneWidget);
    expect(find.textContaining('yet.'), findsNothing);
  });

  testWidgets('Continue stays on screen when the list is longer than it', (tester) async {
    final result = await openDialog(tester, [
      for (var i = 0; i < 30; i++) SubmitConfirmLine(name: 'Item $i', entries: const ['Filled: 1']),
    ]);

    final continueButton = find.text('Continue');
    expect(tester.getRect(continueButton).bottom, lessThanOrEqualTo(640));
    await tester.tap(continueButton); // throws if covered or off-screen
    await tester.pumpAndSettle();
    expect(await result, isTrue);
  });

  testWidgets('Cancel returns false', (tester) async {
    final result = await openDialog(tester, const [SubmitConfirmLine(name: 'A', entries: ['Filled: 1'])]);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}
