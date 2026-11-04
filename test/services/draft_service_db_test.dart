import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/services/draft_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  // `flutter test` runs on the desktop host (Windows/Linux), where plain
  // sqflite has no database factory — the same failure as a desktop run.
  test('opens on desktop and round-trips a draft', () async {
    final store = await DraftService().init(path: inMemoryDatabasePath);

    await store.saveJson('receive_po_1', {'10': [{'qty': 2}]});
    expect(await store.readJson('receive_po_1'), {'10': [{'qty': 2}]});

    await store.remove('receive_po_1');
    expect(await store.readJson('receive_po_1'), isNull);
  });

  test('drafts are kept per company; direct mode keeps the plain scope', () async {
    var company = 'tenant-a';
    final store = await DraftService(namespace: () => company).init(path: inMemoryDatabasePath);

    await store.saveJson('receive_po_42', {'10': [{'qty': 1}]});
    expect(store.keyFor('receive_po_42'), 'tenant-a/receive_po_42');

    // The same PO id in another company is another document.
    company = 'tenant-b';
    expect(await store.readJson('receive_po_42'), isNull);
    await store.saveJson('receive_po_42', {'10': [{'qty': 9}]});

    company = 'tenant-a';
    expect(await store.readJson('receive_po_42'), {'10': [{'qty': 1}]});
    await store.remove('receive_po_42');
    company = 'tenant-b';
    expect(await store.readJson('receive_po_42'), {'10': [{'qty': 9}]});

    // No company (direct mode / signed out): the plain scope, as before.
    company = '';
    expect(store.keyFor('receive_po_42'), 'receive_po_42');
    expect(await store.readJson('receive_po_42'), isNull);
  });
}
