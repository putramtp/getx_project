import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/widget/top_filter_popup.dart';

import 'pump_ui.dart';

/// A list's filter as the popup edits it; counts what Apply / Clear asked for.
class _FakeFilter implements TopFilterController {
  @override
  final startDate = Rx<DateTime?>(null);
  @override
  final endDate = Rx<DateTime?>(null);
  @override
  final limit = 20.obs;
  @override
  final enablePriceRange = false.obs;
  @override
  final minPrice = 0.0.obs;
  @override
  final maxPrice = 100.0.obs;

  int applied = 0;
  int cleared = 0;

  @override
  String formatDate(DateTime date) => '${date.year}-${date.month}-${date.day}';
  @override
  Future<void> pickStartDate(BuildContext context) async => startDate.value = DateTime(2026, 11, 6);
  @override
  Future<void> pickEndDate(BuildContext context) async => endDate.value = DateTime(2026, 11, 1);
  @override
  void applyFilter() => applied++;
  @override
  void clearFilter() {
    cleared++;
    startDate.value = null;
    endDate.value = null;
    limit.value = 20;
  }
}

/// The popup edits the filter in place: closed without Apply or Clear, it must
/// put it back — else the next page loads with a filter the list wasn't loaded
/// with.
void main() {
  Future<_FakeFilter> open(WidgetTester t, {List<Rx> extra = const []}) async {
    final filter = _FakeFilter();
    await pumpUi(
      t,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showTopFilterPopup(context, TopDateFilterPopup(controller: filter), extra: extra),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
    return filter;
  }

  Future<void> dismiss(WidgetTester t) async {
    await t.tapAt(const Offset(200, 790)); // the barrier, below the popup
    await t.pumpAndSettle();
  }

  testWidgets('dismissed without Apply, the picked dates and limit are put back', (t) async {
    final threshold = RxnInt(5);
    final filter = await open(t, extra: [threshold]);

    await t.tap(find.text('Start date'));
    await t.pump();
    filter.limit.value = 200;
    threshold.value = 9;
    expect(filter.startDate.value, isNotNull);

    await dismiss(t);

    expect(find.text('Filter Options'), findsNothing);
    expect(filter.startDate.value, isNull);
    expect(filter.limit.value, 20);
    expect(threshold.value, 5);
    expect(filter.applied, 0);
  });

  testWidgets('Apply keeps what was picked', (t) async {
    final filter = await open(t);

    await t.tap(find.text('Start date'));
    await t.pump();
    await t.tap(find.text('Apply'));
    await t.pumpAndSettle();

    expect(filter.applied, 1);
    expect(filter.startDate.value, DateTime(2026, 11, 6));
  });

  testWidgets('an end date before the start date is refused and, dismissed, undone', (t) async {
    final filter = await open(t);

    await t.tap(find.text('Start date'));
    await t.tap(find.text('End date'));
    await t.pump();
    await t.tap(find.text('Apply'));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(filter.applied, 0);
    expect(find.textContaining('end date is before'), findsOneWidget);

    Get.closeAllSnackbars();
    await t.pumpAndSettle();
    await dismiss(t);

    expect(filter.startDate.value, isNull);
    expect(filter.endDate.value, isNull);
  });

  testWidgets('Clear keeps the cleared filter', (t) async {
    final filter = await open(t);
    filter.limit.value = 100;

    await t.tap(find.text('Clear'));
    await t.pumpAndSettle();

    expect(filter.cleared, 1);
    expect(filter.limit.value, 20);
  });
}
