import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/helpers/list_reload_guard.dart';

class _List extends GetxController with ListReloadGuard {
  final isLoading = false.obs;
  final queries = <String>[];
  String query = '';
  Completer<void>? pending;

  Future<void> reload() => guardReload(isLoading, () async {
        isLoading.value = true;
        queries.add(query);
        pending = Completer<void>();
        await pending!.future;
        isLoading.value = false;
      });
}

void main() {
  test('a reload asked for during a load runs afterwards with the latest query', () async {
    final list = _List();
    list.query = 'val';
    final first = list.reload();

    list.query = 'valve';
    await list.reload(); // queued, returns at once
    expect(list.queries, ['val']);

    list.pending!.complete();
    await pumpEventQueue();
    expect(list.queries, ['val', 'valve']);

    list.pending!.complete();
    await first;
  });

  test('a next page fetched before a reload is no longer current', () async {
    final list = _List();
    final generation = list.listGeneration;
    expect(list.isCurrentPage(generation), isTrue);

    final reload = list.reload();
    expect(list.isCurrentPage(generation), isFalse);

    list.pending!.complete();
    await reload;
  });
}
