import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/models/outflow_request_line_item_model.dart';
import 'package:getx_project/app/data/models/purchase_order_line_item_by_supplier_model.dart';
import 'package:getx_project/app/data/models/purchase_order_line_item_model.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/widget/order_list_widgets.dart';

import '../widgets/pump_ui.dart';

/// The PO/OR summaries say which lines the backend would refuse (`can_receive` /
/// `can_issue` + `blocked_reason`), so the app shows them read-only up front.
void main() {
  group('summary line models', () {
    test('a line the backend refuses carries its reason', () {
      const reason = 'The purchase order line for Cable has no price.';
      final json = {'line_id': 1, 'can_receive': false, 'blocked_reason': reason};

      expect(PurchaseOrderLineItemModel.fromJson(json).blockedReason, reason);
      expect(PurchaseOrderLineItemBySupplierModel.fromJson(json).blockedReason, reason);
      expect(
        OutflowRequestLineItemModel.fromJson({'line_id': 1, 'can_issue': false, 'blocked_reason': 'Not approved.'}).blockedReason,
        'Not approved.',
      );
    });

    test('an open line, or an older backend without the flag, is not blocked', () {
      for (final json in [
        {'line_id': 1, 'can_receive': true, 'blocked_reason': null},
        {'line_id': 1},
      ]) {
        expect(PurchaseOrderLineItemModel.fromJson(json).blockedReason, isNull);
      }
      expect(OutflowRequestLineItemModel.fromJson({'line_id': 1, 'can_issue': true}).blockedReason, isNull);
    });

    test('a refusal without a reason still blocks the line', () {
      expect(OutflowRequestLineItemModel.fromJson({'line_id': 1, 'can_issue': false}).blockedReason, isNotEmpty);
    });
  });

  group('nextOpenLine', () {
    final items = [
      {'line_id': 1},
      {'line_id': 2, 'blocked_reason': 'No price'},
      {'line_id': 3},
      {'line_id': 4, 'blocked_reason': 'No price'},
    ];

    test('skips blocked lines', () {
      expect(nextOpenLine(items, 0), 2);
      expect(isLineBlocked(items[1]), isTrue);
      expect(isLineBlocked(items[0]), isFalse);
    });

    test('is null when only blocked lines are left', () {
      expect(nextOpenLine(items, 2), isNull);
    });
  });

  testWidgets('the Item Summary tile shows why a line is read-only', (t) async {
    await pumpUi(
      t,
      Scaffold(
        body: orderItemSummaryTile(
          size: 9.6,
          name: 'Cable',
          subtitle: 'Expected: 10',
          statusIcon: Icons.lock_rounded,
          statusColor: Colors.grey,
          showAction: false,
          actionLabel: 'Fill',
          actionIcon: Icons.edit_rounded,
          actionColor: Colors.blue,
          onAction: () {},
          blockedReason: 'The purchase order line for Cable has no price.',
        ),
      ),
    );

    expect(find.byKey(const Key('orderLineBlockedReason')), findsOneWidget);
    expect(find.textContaining('has no price'), findsOneWidget);
    expect(find.text('Fill'), findsNothing);
  });
}
