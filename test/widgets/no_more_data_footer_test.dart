import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';

import 'pump_ui.dart';

void main() {
  testWidgets('end-of-list footer leaves room above the system nav bar', (tester) async {
    tester.view.padding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPadding);
    await pumpUi(tester, const Scaffold(body: Column(children: [NoMoreDataFooter(size: 10)])));

    expect(find.text('No more data'), findsOneWidget);
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.text('No more data'), matching: find.byKey(const Key('noMoreDataFooter'))),
    ).padding as EdgeInsets;
    expect(padding.bottom, greaterThanOrEqualTo(10 * 6 + 24));
  });
}
