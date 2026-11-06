import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';

import 'pump_ui.dart';

/// "Edit Serial" on a receive BATCH entry opens the serial dialog with the
/// entry's serial, so changing only its qty or expiry needs no retyping.
void main() {
  testWidgets('opens with the serial being edited and returns it unchanged on Save', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showManualSerialDialog(initialValue: 'LOT-7');
    await t.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'LOT-7'), findsOneWidget);
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    expect(await result, 'LOT-7');
  });

  testWidgets('a new entry still opens empty', (t) async {
    await pumpUi(t, const Scaffold());
    final result = showManualSerialDialog();
    await t.pumpAndSettle();

    final field = t.widget<TextField>(find.byKey(const Key('serialDialogField')));
    expect(field.controller?.text, '');

    await t.enterText(find.byKey(const Key('serialDialogField')), ' LOT-9 ');
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();

    expect(await result, 'LOT-9');
  });
}
