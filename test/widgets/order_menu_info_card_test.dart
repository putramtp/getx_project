import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/widget/order_menu_widgets.dart';

import 'pump_ui.dart';

void main() {
  testWidgets('info card shows title, subtitle and opens on tap', (tester) async {
    var taps = 0;
    await pumpUi(
      tester,
      Scaffold(
        body: orderMenuInfoCard(
          size: 9.6,
          title: 'Deliveries',
          subtitle: 'Track & dispatch deliveries',
          icon: Icons.local_shipping_rounded,
          accent: AppAccent.steel,
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.text('Deliveries'), findsOneWidget);
    expect(find.text('Track & dispatch deliveries'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);
    await tester.tap(find.text('Deliveries'));
    expect(taps, 1);
  });
}
