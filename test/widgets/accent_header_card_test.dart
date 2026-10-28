import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/accent_header_card.dart';
import 'package:getx_project/app/global/widget/accent_pill.dart';

import 'pump_ui.dart';

void main() {
  Future<void> pump(WidgetTester t, Widget card, {double width = 400}) =>
      pumpUi(t, Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: card)), width: width);

  test('headerFooterText drops missing parts', () {
    expect(headerFooterText(['PT Mitra', null, '  ', 'RN-1']), 'PT Mitra · RN-1');
    expect(headerFooterText([null, '']), isNull);
  });

  testWidgets('renders label, title, code, stats and caption', (tester) async {
    await pump(
      tester,
      accentHeaderCard(
        size: 9.6,
        accent: AppAccent.sky,
        icon: Icons.request_page_rounded,
        label: 'Purchase order',
        title: '#PO-2026-0187',
        code: 'BR-007',
        badge: accentPill(9.6, 'Processing', accent: AppAccent.sky),
        stats: const [HeaderStat('Expected', '48'), HeaderStat('Received', '20', color: navyMid)],
        footer: 'PT Mitra Logistik · 2026-10-27',
        progress: const AccentProgress(
          [ProgressSegment(20 / 48, navyMid, legend: 'Received'), ProgressSegment(8 / 48, skyBlue, legend: 'Now')],
          caption: '1 of 3 lines complete',
          showLegend: true,
        ),
      ),
    );
    for (final t in ['Purchase order', '#PO-2026-0187', 'BR-007', 'Expected', '48', '1 of 3 lines complete']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
  });

  testWidgets('footer null renders no footer row', (tester) async {
    await pump(
      tester,
      accentHeaderCard(
        size: 9.6,
        accent: AppAccent.sage,
        icon: Icons.storefront_rounded,
        label: 'Supplier',
        title: 'Indo Kemas',
        footerIcon: Icons.store_rounded,
      ),
    );
    expect(find.byIcon(Icons.store_rounded), findsNothing);
  });

  testWidgets('progress clamps out-of-range segments', (tester) async {
    await pump(
      tester,
      accentHeaderCard(
        size: 9.6,
        accent: AppAccent.sky,
        icon: Icons.edit_note_rounded,
        label: 'Item',
        title: 'Over-filled',
        progress: const AccentProgress([
          ProgressSegment(0.9, navyMid),
          ProgressSegment(0.5, skyBlue),
          ProgressSegment(-0.2, Colors.red),
        ], caption: 'over'),
      ),
    );
    expect(tester.takeException(), isNull);
    final track = tester.getSize(find.byKey(const Key('accentProgressTrack'))).width;
    final filled = find
        .byKey(const Key('accentProgressSegment'))
        .evaluate()
        .fold<double>(0, (a, e) => a + e.size!.width);
    expect(filled, lessThanOrEqualTo(track + 0.001));
    expect(filled, closeTo(track, 0.001)); // 0.9 + 0.5 capped at 1, -0.2 → 0
  });

  testWidgets('no overflow at 320 dp', (tester) async {
    await pump(
      tester,
      accentHeaderCard(
        size: 7.68,
        accent: AppAccent.amber,
        icon: Icons.qr_code_scanner_rounded,
        label: 'Item',
        title: 'Scanner Zebra DS2208 Barcode Reader Black',
        badge: accentPill(7.68, '12 left', accent: AppAccent.amber, outlined: true),
        stats: const [
          HeaderStat('Reserved', '1200'),
          HeaderStat('Received', '1000'),
          HeaderStat('Scanned', '150'),
          HeaderStat('Remaining', '50', color: Colors.red),
        ],
        footer: 'PT Sinar Jaya Abadi Sentosa Makmur · BILL-2026-000000123456',
      ),
      width: 320,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('metric card shows each metric with its own gradient icon tile', (tester) async {
    await pump(
      tester,
      accentMetricCard(
        size: 9.6,
        accent: AppAccent.slate,
        metrics: const [
          HeaderMetric('Total products', '248', icon: Icons.inventory_2_rounded, accent: AppAccent.navy),
          HeaderMetric('Stock in hand', '12480', icon: Icons.layers_rounded, accent: AppAccent.sage),
        ],
        footer: const Text('2 low stock'),
      ),
      width: 320,
    );
    for (final t in ['TOTAL PRODUCTS', '248', 'STOCK IN HAND', '12480', '2 low stock']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    for (final (icon, accent) in [(Icons.inventory_2_rounded, AppAccent.navy), (Icons.layers_rounded, AppAccent.sage)]) {
      final tile = find.ancestor(of: find.byIcon(icon), matching: find.byKey(const Key('headerMetricIcon')));
      final deco = tester.widget<Container>(tile).decoration! as BoxDecoration;
      expect(deco.gradient, accent.gradient, reason: '$icon');
    }
    expect(tester.takeException(), isNull);
  });
}
