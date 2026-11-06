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

  test('an already-saved answer also drops the spent draft and asks for a reload', () async {
    await drafts.saveJson('receive_po_9', {'10': [{'qty': 5}]});
    var reloads = 0;
    final key = SubmitKey(drafts, 'receive_po_9', onAlreadySaved: () => reloads++);

    await expectLater(
      key.send((_) async => throw SubmitAlreadySavedException('already saved')),
      throwsA(isA<SubmitAlreadySavedException>()),
    );
    // Kept, the next tap would send it with a fresh key and book it twice.
    expect(await drafts.readJson('receive_po_9'), isNull);
    expect(reloads, 1);
  });

  test('a plain failure keeps the draft and does not reload', () async {
    await drafts.saveJson('receive_po_8', {'10': [{'qty': 5}]});
    var reloads = 0;
    final key = SubmitKey(drafts, 'receive_po_8', onAlreadySaved: () => reloads++);

    await expectLater(key.send((_) async => throw Exception('No response from server.')), throwsException);
    expect(await drafts.readJson('receive_po_8'), {'10': [{'qty': 5}]});
    expect(reloads, 0);
  });

  test('a 4xx refusal drops the key (nothing booked) but keeps the draft', () async {
    await drafts.saveJson('receive_po_5', {'10': [{'qty': 5}]});
    final key = SubmitKey(drafts, 'receive_po_5');
    final first = await key.current();

    await expectLater(
      key.send((_) async => throw RequestRefusedException(422, 'The qty is invalid.')),
      throwsA(isA<RequestRefusedException>()),
    );
    expect(await key.isPending(), isFalse);
    expect(await key.current(), isNot(first));
    expect(await drafts.readJson('receive_po_5'), {'10': [{'qty': 5}]});
  });

  test('a 5xx, 408, 409 or 429 keeps the key: the submit may still be booked', () async {
    for (final code in [500, 502, 408, 409, 429]) {
      final key = SubmitKey(drafts, 'outflow_or_$code');
      final first = await key.current();
      await expectLater(
        key.send((_) async => throw RequestRefusedException(code, 'HTTP $code')),
        throwsA(isA<RequestRefusedException>()),
      );
      expect(await key.isPending(), isTrue, reason: '$code');
      expect(await key.current(), first, reason: '$code');
    }
  });

  test('a refusal reads like a plain Exception for the user', () {
    expect(RequestRefusedException(422, 'The qty is invalid.').toString(), 'Exception: The qty is invalid.');
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
