import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/qty_input_dialogs.dart';

import 'pump_ui.dart';

/// Quantity-only lines take fractional quantities (kg, metre); serial-tracked
/// UNIQUE/BATCH lines count whole units.
void main() {
  Future<void> type(WidgetTester t, String text, String button) async {
    await t.enterText(find.byKey(const Key('qtyDialogField')), text);
    await t.tap(find.text(button));
    // Step frames rather than pumpAndSettle so an error snackbar gets shown.
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> drainSnackbars(WidgetTester t) async {
    Get.closeAllSnackbars();
    await t.pumpAndSettle();
  }

  testWidgets('item quantity accepts a comma decimal', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showOtherItemDialog();
    await t.pumpAndSettle();

    await type(t, '2,5', 'Save');

    expect(await result, {'qty': 2.5});
  });

  testWidgets('batch quantity rejects a fraction and stays open', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showBatchQtyDialog();
    await t.pumpAndSettle();

    await type(t, '1.5', 'OK');
    expect(find.text('Batch Quantity'), findsOneWidget);
    expect(find.textContaining('whole number'), findsOneWidget);

    await type(t, '2', 'OK');
    expect(await result, 2);
    await drainSnackbars(t);
  });

  testWidgets('receive quantity keeps a decimal for a quantity-only line', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showReceiveItemQtyDialog(accent: Colors.blue, initialQty: 0.25);
    await t.pumpAndSettle();

    expect(find.text('0.25'), findsOneWidget);
    await type(t, '12.75', 'Save');

    expect((await result)?['qty'], 12.75);
  });

  Future<void> settleFrames(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('"1.500" asks which reading was meant — thousands', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showOtherItemDialog();
    await t.pumpAndSettle();

    await type(t, '1.500', 'Save');
    expect(find.text('Which quantity?'), findsOneWidget);

    await t.tap(find.byKey(const Key('qtyReadingThousands')));
    await settleFrames(t);

    expect(await result, {'qty': 1500});
    expect(find.text('Which quantity?'), findsNothing);
  });

  testWidgets('"1.500" asks which reading was meant — decimal', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showReceiveItemQtyDialog(accent: Colors.blue);
    await t.pumpAndSettle();

    await type(t, '1.500', 'Save');
    await t.tap(find.byKey(const Key('qtyReadingDecimal')));
    await settleFrames(t);

    expect((await result)?['qty'], 1.5);
  });

  testWidgets('cancelling the reading keeps the quantity dialog open', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showOtherItemDialog();
    await t.pumpAndSettle();

    await type(t, '12,250', 'Save');
    await t.tap(find.text('Cancel').last);
    await settleFrames(t);

    expect(find.text('Which quantity?'), findsNothing);
    expect(find.text('Enter item quantity'), findsOneWidget);

    await type(t, '12.25', 'Save');
    expect(await result, {'qty': 12.25});
  });

  testWidgets('a whole-unit line refuses "1.500" instead of asking', (t) async {
    await pumpUi(t, const Scaffold());
    showBatchQtyDialog();
    await t.pumpAndSettle();

    await type(t, '1.500', 'OK');

    expect(find.text('Which quantity?'), findsNothing);
    expect(find.text('Batch Quantity'), findsOneWidget);
    expect(find.textContaining('thousands separator'), findsOneWidget);
    await drainSnackbars(t);
  });

  testWidgets('receive quantity for a serial-tracked line rejects a fraction', (t) async {
    await pumpUi(t, const Scaffold());
    showReceiveItemQtyDialog(accent: Colors.blue, wholeUnits: true);
    await t.pumpAndSettle();

    await type(t, '2.5', 'Save');

    expect(find.text('Enter item quantity'), findsOneWidget);
    expect(find.textContaining('whole number'), findsOneWidget);
    await drainSnackbars(t);
  });
}
