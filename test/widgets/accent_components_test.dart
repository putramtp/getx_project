import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/accent_pill.dart';
import 'package:getx_project/app/global/widget/app_buttons.dart';
import 'package:getx_project/app/global/widget/stock_direction_icon.dart';

import 'pump_ui.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget child) =>
      pumpUi(t, Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: Column(children: [child]))));

  Color? textColor(WidgetTester t, String text) => t.widget<Text>(find.text(text)).style?.color;

  testWidgets('navyButton calls onPressed and shows label', (tester) async {
    var taps = 0;
    await pump(tester, navyButton(10, 'Continue', onPressed: () => taps++, icon: Icons.receipt_long_rounded));
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
  });

  testWidgets('navyButton loading ignores taps', (tester) async {
    var taps = 0;
    await pump(tester, navyButton(10, 'Continue', onPressed: () => taps++, loading: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(CircularProgressIndicator), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('navyButton disabled when onPressed null', (tester) async {
    await pump(tester, navyButton(10, 'Continue', onPressed: null));
    await tester.tap(find.text('Continue'), warnIfMissed: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accentOutlineButton falls back to navy for white API colors', (tester) async {
    await pump(tester, accentOutlineButton(10, 'Mark Shipped', color: const Color(0xFFFFFFFF), onPressed: () {}));
    expect(textColor(tester, 'Mark Shipped'), navyMid);
  });

  testWidgets('accentPill uses the dark text shade', (tester) async {
    await pump(tester, accentPill(10, '12 left', accent: AppAccent.amber));
    expect(textColor(tester, '12 left'), amberDark);
  });

  testWidgets('statusPill makes light API colors readable', (tester) async {
    await pump(tester, statusPill(10, 'Pending', const Color(0xFFFFFFFF)));
    expect(textColor(tester, 'Pending'), navyMid);
  });

  testWidgets('stockDirectionIcon shows south for IN, north for OUT', (tester) async {
    await pump(tester, Row(children: [stockDirectionIcon(10, isIn: true), stockDirectionIcon(10, isIn: false)]));
    expect(tester.widget<Icon>(find.byIcon(Icons.south_rounded)).color, stockInColor);
    expect(tester.widget<Icon>(find.byIcon(Icons.north_rounded)).color, stockOutColor);
  });

  testWidgets('softIconButton is a square navy-tinted button found by its tooltip', (tester) async {
    var taps = 0;
    await pump(tester, softIconButton(10, Icons.search, tooltip: 'Search', onPressed: () => taps++));

    final button = find.byTooltip('Search');
    expect(tester.getSize(button), const Size(28, 28)); // mockup: 28 × 28
    expect(tester.widget<Icon>(find.byIcon(Icons.search)).color, navyMid);
    await tester.tap(button);
    expect(taps, 1);
  });
}
