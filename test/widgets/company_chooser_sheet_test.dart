import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/data/models/workspace_sign_in_model.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/modules/login/views/company_chooser_sheet.dart';

const _tenants = [
  WorkspaceTenant(id: 'a', name: 'Acme', host: 'acme.example.com'),
  WorkspaceTenant(id: 'b', name: 'Beta', host: 'beta.example.com'),
];

Future<void> _pumpHost(WidgetTester tester, void Function(Future<WorkspaceTenant?>) onOpen) async {
  await tester.pumpWidget(GetMaterialApp(
    home: Builder(builder: (context) {
      SizeConfig.init(context);
      return Scaffold(
        body: TextButton(onPressed: () => onOpen(showCompanyChooser(_tenants)), child: const Text('open')),
      );
    }),
  ));
}

void main() {
  testWidgets('lists every company and resolves with the tapped one', (tester) async {
    late Future<WorkspaceTenant?> result;
    await _pumpHost(tester, (f) => result = f);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a company'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('beta.example.com'), findsOneWidget);

    await tester.tap(find.byKey(const Key('loginCompanyChoice_1')));
    await tester.pumpAndSettle();
    expect((await result)?.id, 'b');
    expect(find.text('Choose a company'), findsNothing);
  });

  testWidgets('dismissing the sheet resolves with null', (tester) async {
    late Future<WorkspaceTenant?> result;
    await _pumpHost(tester, (f) => result = f);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10)); // the barrier above the sheet
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
