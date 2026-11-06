import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;

import '../global/alert.dart';
import '../global/functions.dart';
import '../global/submit_key.dart';

/// A GetxService providing durable, on-device storage for in-progress work
/// ("drafts") so a worker never loses a batch of scans/fills to an app kill,
/// crash, or an offline/failed submit.
///
/// Backed by a single sqflite table keyed by an opaque [scope] string
/// (e.g. `receive_po_42`, `outflow_or_7`, `receive_confirm_13`). The value is a
/// JSON blob — all draft payloads are already plain `Map`/`List` of
/// String/int/null, so no type adapters are needed.
///
/// Registered permanently and opened asynchronously in main() via
/// `Get.putAsync`, mirroring [AuthService].
///
/// **Per company and per user:** document ids only mean something inside one
/// company (PO 42 of company A is not PO 42 of company B), and one worker's
/// half-filled document must not reach the next worker on a shared phone. So
/// every scope is stored under [namespace] — `<tenantId>/<account>/receive_po_42`
/// in workspace mode, `<account>/…` in direct mode (account = the email or
/// username typed to sign in, `AuthService.account`). A session signed in
/// before accounts were stored has none and keeps the older key.
class DraftService extends GetxService {
  DraftService({this.namespace});

  /// The signed-in company's id, or '' (direct mode / signed out).
  final String Function()? namespace;

  /// The stored key of [scope] for the current company.
  @visibleForTesting
  String keyFor(String scope) {
    final ns = namespace?.call().trim() ?? '';
    return ns.isEmpty ? scope : '$ns/$scope';
  }

  static const String _dbName = 'warehouse_drafts.db';
  static const String _table = 'drafts';

  late final Database _db;

  /// Opens (creating on first run) the drafts database. Must complete before
  /// any controller reads/writes a draft. [path] overrides the file location
  /// (tests pass `inMemoryDatabasePath`).
  Future<DraftService> init({String? path}) async {
    final factory = _databaseFactory();
    final dbPath = path ?? p.join(await factory.getDatabasesPath(), _dbName);
    _db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_table (
              scope TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    return this;
  }

  /// Plain sqflite only ships a factory for Android/iOS/macOS; Windows and
  /// Linux (desktop runs, `flutter test`) go through the FFI one.
  static DatabaseFactory _databaseFactory() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactorySqflitePlugin;
  }

  /// Persist [jsonValue] (any JSON-encodable Map/List) under [scope],
  /// replacing any existing draft for that scope.
  Future<void> saveJson(String scope, Object jsonValue) async {
    await _db.insert(
      _table,
      {
        'scope': keyFor(scope),
        'payload': jsonEncode(jsonValue),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Read and decode the draft stored under [scope], or null if none.
  Future<dynamic> readJson(String scope) async {
    final rows = await _db.query(
      _table,
      columns: ['payload'],
      where: 'scope = ?',
      whereArgs: [keyFor(scope)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload = rows.first['payload'];
    if (payload is! String) return null;
    return jsonDecode(payload);
  }

  /// Delete the draft under [scope] (no-op if absent).
  Future<void> remove(String scope) async {
    await _db.delete(_table, where: 'scope = ?', whereArgs: [keyFor(scope)]);
  }
}

/// Decode a line-keyed draft — the shape shared by the receive-fill and
/// outflow-scan flows: `{ "<lineId>": [ {entry}, ... ] }`. Returns an empty map
/// when there is no draft. Kept here so all four detail controllers overlay
/// cached work with identical logic (DRY).
Future<Map<String, List<Map<String, dynamic>>>> readLineDraft(
    DraftService store, String scope) async {
  final raw = await store.readJson(scope);
  if (raw is! Map) return {};
  final result = <String, List<Map<String, dynamic>>>{};
  raw.forEach((key, value) {
    if (value is List) {
      result[key.toString()] = value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
  });
  return result;
}

/// A line's restored draft [cached] when its total still fits [open] (what is
/// left to receive / outflow on the line now); null when it doesn't — someone
/// else booked part of the line meanwhile, or its qty shrank — so the stale
/// draft is cleared instead of failing the whole submit later.
List<Map<String, dynamic>>? draftThatFits(List<Map<String, dynamic>>? cached, num open) {
  if (cached == null) return null;
  return roundQty(sumQty(cached)) <= roundQty(open) ? cached : null;
}

/// Tells the worker which lines lost their saved entries ([draftThatFits]).
/// With a submit of [scope] still unanswered, the likeliest cause is that
/// submit itself — booked, its answer lost — not someone else: say so, rather
/// than blame the line.
Future<void> showClearedDrafts(DraftService store, String scope, List<String> names) async {
  if (names.isEmpty) return;
  final lines = names.join(', ');
  final pending = await SubmitKey(store, scope).isPending();
  warningAlertBottom(
    pending
        ? 'Your last submit may have been saved before its answer was lost: the entries for $lines '
            'are more than what is left now and were cleared. Check the history before submitting again.'
        : 'Saved entries for $lines no longer fit what is left on the line and were cleared.',
    title: 'Draft Cleared',
  );
}

/// Build the line-keyed draft map from a controller's `items` list, collecting
/// only lines that have at least one entry under [fillKey] (`"filled"` for
/// receive, `"scanned"` for outflow). An empty result signals the caller to
/// remove the draft instead of writing an empty one.
Map<String, dynamic> buildLineDraftMap(List items, String fillKey) {
  final map = <String, dynamic>{};
  for (final item in items) {
    final list = List<Map<String, dynamic>>.from(item[fillKey] ?? const []);
    if (list.isNotEmpty) map[item['line_id'].toString()] = list;
  }
  return map;
}
