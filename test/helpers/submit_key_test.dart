import 'package:flutter_test/flutter_test.dart';
import 'package:getx_project/app/data/providers/api_providers.dart';
import 'package:getx_project/app/global/submit_key.dart';
import 'package:getx_project/app/services/draft_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  late DraftService drafts;

  setUp(() async {
    drafts = await DraftService().init(path: inMemoryDatabasePath);
  });

  test('a failed submit keeps its key, so the retry sends the same one', () async {
    final sent = <String>[];
    final key = SubmitKey(drafts, 'receive_po_1');

    await expectLater(
      key.send((k) async {
        sent.add(k);
        throw Exception('No response from server.');
      }),
      throwsException,
    );
    // Reopening the screen builds a new SubmitKey for the same scope.
    await SubmitKey(drafts, 'receive_po_1').send((k) async => sent.add(k));

    expect(sent, hasLength(2));
    expect(sent[0], sent[1]);
  });

  test('a successful submit drops its key; the next submit gets a new one', () async {
    final key = SubmitKey(drafts, 'outflow_or_7');
    final first = await key.send((k) async => k);
    final second = await key.send((k) async => k);

    expect(first, isNot(second));
    expect(await drafts.readJson('outflow_or_7:submit_key'), isNull);
  });

  test('an already-saved answer drops the spent key', () async {
    final key = SubmitKey(drafts, 'outflow_cust_3');
    final spent = await key.current();

    await expectLater(
      key.send((_) async => throw SubmitAlreadySavedException('already saved')),
      throwsA(isA<SubmitAlreadySavedException>()),
    );
    expect(await key.current(), isNot(spent));
  });

  test('keys are per scope and never touch the line draft', () async {
    await drafts.saveJson('receive_po_1', {'10': [{'qty': 2}]});
    final a = await SubmitKey(drafts, 'receive_po_1').current();
    final b = await SubmitKey(drafts, 'receive_po_2').current();

    expect(a, isNot(b));
    expect(a, matches(RegExp(r'^app-[0-9a-f]{32}$')));
    expect(await drafts.readJson('receive_po_1'), {'10': [{'qty': 2}]});
  });
}
