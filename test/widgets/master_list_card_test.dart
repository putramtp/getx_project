import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/widget/master_list_view.dart';

import 'pump_ui.dart';

void main() {
  Future<void> pump(WidgetTester t, MasterKind kind, {bool subtitleMissing = false}) => pumpUi(
        t,
        Scaffold(
          body: masterListCard(
            size: 9.6,
            kind: kind,
            avatarText: 'IK',
            title: 'Indo Kemas',
            subtitle: subtitleMissing ? 'No description' : 'indo-kemas',
            subtitleMissing: subtitleMissing,
            onTap: () {},
          ),
        ),
      );

  testWidgets('master card tile uses palette accent', (tester) async {
    await pump(tester, MasterKind.brand);
    final tile = tester.widget<Container>(find.byKey(const Key('masterListTile')));
    expect((tile.decoration as BoxDecoration).color, accentFor('Indo Kemas').tint(.14));
    expect(tester.widget<Text>(find.text('IK')).style?.color, accentFor('Indo Kemas').text);
  });

  testWidgets('kind badge icon', (tester) async {
    await pump(tester, MasterKind.brand);
    expect(find.byIcon(Icons.sell_rounded), findsOneWidget);
    await pump(tester, MasterKind.category);
    expect(find.byIcon(Icons.category_rounded), findsOneWidget);
    await pump(tester, MasterKind.unit);
    expect(find.byIcon(Icons.straighten_rounded), findsOneWidget);
  });

  testWidgets('missing subtitle is italic grey', (tester) async {
    await pump(tester, MasterKind.unit, subtitleMissing: true);
    expect(tester.widget<Text>(find.text('No description')).style?.fontStyle, FontStyle.italic);
  });
}
