import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/functions.dart';

/// GetX 4.7's Get.back() closes an open snackbar *instead of* the route, so a
/// dialog/sheet closed right after an alert stayed up (and a second tap could
/// act on stale state). closeRoute() must close the route regardless.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
  }

  Future<void> showSnackbar(WidgetTester tester) async {
    Get.snackbar('Warning', 'an alert is showing', duration: const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> drainSnackbars(WidgetTester tester) async {
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  }

  testWidgets('closes a dialog while a snackbar is showing and returns the result', (tester) async {
    await pumpApp(tester);
    await showSnackbar(tester);
    final result = Get.dialog<bool>(const AlertDialog(title: Text('Confirm?')));
    await tester.pumpAndSettle();

    closeRoute(true);
    await tester.pumpAndSettle();

    expect(find.text('Confirm?'), findsNothing);
    expect(await result, isTrue);
    await drainSnackbars(tester);
  });

  testWidgets('closes synchronously, so a route opened right after it survives', (tester) async {
    await pumpApp(tester);
    Get.bottomSheet(const Material(child: Text('Account sheet')));
    await tester.pumpAndSettle();

    // Same shape as the home account menu: close the sheet, open a dialog.
    closeRoute();
    Get.dialog(const AlertDialog(title: Text('Account Info')));
    await tester.pumpAndSettle();

    expect(find.text('Account sheet'), findsNothing);
    expect(find.text('Account Info'), findsOneWidget);
  });

  testWidgets('closes a bottom sheet while a snackbar is showing', (tester) async {
    await pumpApp(tester);
    await showSnackbar(tester);
    Get.bottomSheet(const Material(child: Text('Remove')));
    await tester.pumpAndSettle();

    closeRoute();
    await tester.pumpAndSettle();

    expect(find.text('Remove'), findsNothing);
    await drainSnackbars(tester);
  });
}
