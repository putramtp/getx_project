import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/order_fill_widgets.dart';

import 'pump_ui.dart';

void main() {
  testWidgets('bottom bar sits above the 3-button navigation bar', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.resetPadding);
    await pumpUi(
      tester,
      Scaffold(
        bottomNavigationBar: orderFillBottomBar(
          size: 9.6,
          clearEnabled: true,
          onClear: () {},
          continueEnabled: true,
          onContinue: () {},
          accent: skyBlue,
        ),
      ),
    );
    final continueBottom = tester.getRect(find.text('Continue')).bottom;
    expect(continueBottom, lessThanOrEqualTo(800 - 48));
  });

  testWidgets('bottom bar uses navy gradient', (tester) async {
    await pumpUi(
      tester,
      Scaffold(
        bottomNavigationBar: orderFillBottomBar(
          size: 9.6,
          clearEnabled: true,
          onClear: () {},
          continueEnabled: true,
          onContinue: () {},
          accent: mutedPurple,
        ),
      ),
    );
    final navy = find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient == navyGradient,
    );
    expect(navy, findsOneWidget);
    expect(tester.widget<Text>(find.text('Continue')).style?.color, Colors.white);
  });

  testWidgets('scan fab is white with accent icon', (tester) async {
    await pumpUi(
      tester,
      Scaffold(
        floatingActionButton: orderScanFab(
          size: 9.6,
          color: mutedPurple,
          icon: Icons.qr_code_scanner_rounded,
          onPressed: () {},
        ),
      ),
    );
    expect(tester.widget<FloatingActionButton>(find.byType(FloatingActionButton)).backgroundColor, Colors.white);
    expect(tester.widget<Icon>(find.byIcon(Icons.qr_code_scanner_rounded)).color, mutedPurple);
  });

  testWidgets('results title shows count', (tester) async {
    await pumpUi(
      tester,
      Scaffold(
        body: Column(
          children: [
            orderFillResultsTitle(10, 'Filled Results', count: 2, accent: AppAccent.sky),
            orderFillResultsTitle(10, 'Scanned Results', count: 1, accent: AppAccent.sky),
          ],
        ),
      ),
    );
    expect(find.text('Filled Results'), findsOneWidget);
    expect(find.text('2 entries'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);
  });

  testWidgets('fill item header shows remaining badge and stats', (tester) async {
    Widget header(int done) => orderFillItemHeader(
          9.6,
          accent: AppAccent.sky,
          name: 'Scanner Zebra DS2208',
          targetLabel: 'Expected',
          target: 10,
          received: 4,
          doneLabel: 'Filled',
          done: done,
        );
    await pumpUi(tester, Scaffold(body: Column(children: [header(3)])));
    expect(find.text('3 left'), findsOneWidget);
    expect(find.text('Expected'), findsOneWidget);
    expect(find.text('Filled'), findsOneWidget);
    expect(find.text('Remaining'), findsOneWidget);

    await pumpUi(tester, Scaffold(body: Column(children: [header(6)])));
    expect(find.text('Done'), findsOneWidget);
  });
}
