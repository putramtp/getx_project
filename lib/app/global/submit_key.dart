import 'dart:math';

import '../data/providers/api_providers.dart';
import '../services/draft_service.dart';

/// The idempotency key of one pending submit (receive / outflow / work-order
/// issue), kept in [DraftService] next to the draft it submits.
///
/// If the tunnel drops the answer after the server already saved the
/// document, the worker's retry — on the same screen, after reopening it, or
/// after an app restart — sends the same key, and the backend replays the
/// saved answer instead of booking the document and its stock twice.
///
/// The key lives until a submit succeeds (or the server says it is spent), so
/// the next submit of the same scope gets a fresh one.
class SubmitKey {
  SubmitKey(this._drafts, String draftScope) : _scope = '$draftScope:submit_key';

  final DraftService _drafts;
  final String _scope;

  /// The pending key, created and stored on first use.
  Future<String> current() async {
    final stored = await _drafts.readJson(_scope);
    if (stored is String && stored.isNotEmpty) return stored;
    final key = newKey();
    await _drafts.saveJson(_scope, key);
    return key;
  }

  Future<void> clear() => _drafts.remove(_scope);

  /// Runs [post] with the pending key and drops the key once it is used up: on
  /// success, or when the server answers that it was already spent. Any other
  /// failure keeps it, so the retry is recognised.
  Future<T> send<T>(Future<T> Function(String key) post) async {
    final key = await current();
    try {
      final result = await post(key);
      await clear();
      return result;
    } on SubmitAlreadySavedException {
      await clear();
      rethrow;
    }
  }

  static final Random _random = Random.secure();

  /// 128 random bits as hex, prefixed so a key is recognisable in the logs.
  static String newKey() =>
      'app-${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
