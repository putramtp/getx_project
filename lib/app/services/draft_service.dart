import 'dart:convert';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
class DraftService extends GetxService {
  static const String _dbName = 'warehouse_drafts.db';
  static const String _table = 'drafts';

  late final Database _db;

  /// Opens (creating on first run) the drafts database. Must complete before
  /// any controller reads/writes a draft.
  Future<DraftService> init() async {
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
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
    );
    return this;
  }

  /// Persist [jsonValue] (any JSON-encodable Map/List) under [scope],
  /// replacing any existing draft for that scope.
  Future<void> saveJson(String scope, Object jsonValue) async {
    await _db.insert(
      _table,
      {
        'scope': scope,
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
      whereArgs: [scope],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final payload = rows.first['payload'];
    if (payload is! String) return null;
    return jsonDecode(payload);
  }

  /// Delete the draft under [scope] (no-op if absent).
  Future<void> remove(String scope) async {
    await _db.delete(_table, where: 'scope = ?', whereArgs: [scope]);
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
