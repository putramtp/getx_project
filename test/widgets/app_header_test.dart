import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/app_header.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'pump_ui.dart';

void main() {
  const back = Key('appBarBackButton');

  testWidgets('renders title, subtitle and white tile icon', (tester) async {
    await pumpUi(
        tester,
        Scaffold(
            appBar: appHeader('Item Summary',
                accent: AppAccent.sky,
                icon: Icons.receipt_long_rounded,
                subtitle: 'By PO · PO-2026-0187')));

    expect(find.text('Item Summary'), findsOneWidget);
    expect(find.text('By PO · PO-2026-0187'), findsOneWidget);
    final icon = tester.widget<Icon>(find.byIcon(Icons.receipt_long_rounded));
    expect(icon.color, skyBlue);
  });

  testWidgets('back pops the route', (tester) async {
    await pumpUi(tester, const Scaffold(body: Text('First')));
    Get.to(() => Scaffold(appBar: appHeader('Second', accent: AppAccent.sky, icon: Icons.list_alt_rounded)));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsOneWidget);

    await tester.tap(find.byKey(back));
    await tester.pumpAndSettle();
    expect(find.text('Second'), findsNothing);
  });

  testWidgets('onBack overrides pop', (tester) async {
    var tapped = false;
    await pumpUi(tester, const Scaffold(body: Text('First')));
    Get.to(() => Scaffold(
        appBar: appHeader('Second',
            accent: AppAccent.sky, icon: Icons.list_alt_rounded, onBack: () => tapped = true)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(back));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('showBack false hides the back button', (tester) async {
    await pumpUi(
        tester,
        Scaffold(
            appBar: appHeader('Root', accent: AppAccent.navy, icon: Icons.home_rounded, showBack: false)));
    expect(find.byKey(back), findsNothing);
  });

  testWidgets('subtitleLoading shows a skeleton', (tester) async {
    await pumpUi(
        tester,
        Scaffold(
            appBar: appHeader('Item Summary',
                accent: AppAccent.sky,
                icon: Icons.list_alt_rounded,
                subtitle: 'loading',
                subtitleLoading: true)));
    expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);
  });

  testWidgets('long text does not overflow at 320 dp', (tester) async {
    await pumpUi(
        tester,
        Scaffold(
            appBar: appHeader('Outflow Order Detail Summary',
                accent: AppAccent.amber,
                icon: Icons.list_alt_rounded,
                subtitle: 'By Customer · PT Sinar Jaya Abadi Sentosa Makmur',
                actions: [headerAction(Icons.refresh_rounded, tooltip: 'Refresh', onPressed: () {})])),
        width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('obxHeader rebuilds when an Rx subtitle changes', (tester) async {
    final item = 'Item A'.obs;
    await pumpUi(
        tester,
        Scaffold(
            appBar: obxHeader(() => appHeader('Fill Item',
                accent: AppAccent.sky, icon: Icons.edit_note_rounded, subtitle: 'PO-1 · ${item.value}'))));
    expect(find.text('PO-1 · Item A'), findsOneWidget);

    item.value = 'Item B';
    await tester.pump();
    expect(find.text('PO-1 · Item B'), findsOneWidget);
  });

  testWidgets('navy gradient fills the whole bar', (tester) async {
    await pumpUi(
        tester, Scaffold(appBar: appHeader('Products', accent: AppAccent.slate, icon: Icons.inventory_2_rounded)));
    final bg = find.byWidgetPredicate(
        (w) => w is DecoratedBox && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).gradient == navyGradient);
    expect(bg, findsOneWidget);
    final bar = tester.getSize(find.byType(AppBar));
    expect(tester.getSize(bg), bar);
  });
}
