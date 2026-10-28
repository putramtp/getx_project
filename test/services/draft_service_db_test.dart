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
}
