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
  SubmitKey(this._drafts, this._draftScope, {this.onAlreadySaved}) : _scope = '$_draftScope:submit_key';

  final DraftService _drafts;
  final String _draftScope;
  final String _scope;

  /// Runs after the server answered `submit_already_saved` (the draft was
  /// already booked by an earlier try whose answer got lost): the screen
  /// reloads its lines, which now show that booking.
  final void Function()? onAlreadySaved;

  /// The pending key, created and stored on first use.
  Future<String> current() async {
    final stored = await _drafts.readJson(_scope);
    if (stored is String && stored.isNotEmpty) return stored;
    final key = newKey();
    await _drafts.saveJson(_scope, key);
    return key;
  }

  Future<void> clear() => _drafts.remove(_scope);

  /// Whether a submit of this scope is still unanswered (its key is kept):
  /// it may already be booked, its answer lost — a refused submit drops its
  /// key ([send]), so it doesn't count. Reads only — creates no key.
  Future<bool> isPending() async {
    final stored = await _drafts.readJson(_scope);
    return stored is String && stored.isNotEmpty;
  }

  /// Runs [post] with the pending key and drops the key once it is used up: on
  /// success, when the server answers that it was already spent, or when it
  /// refused the submit outright ([RequestRefusedException.refusedWithoutBooking]:
  /// nothing booked, the backend released the key). A failure that may hide a
  /// booking — no answer, a 5xx, "still running" — keeps it, so the retry is
  /// recognised and [isPending] stays true.
  Future<T> send<T>(Future<T> Function(String key) post) async {
    final key = await current();
    try {
      final result = await post(key);
      await clear();
      return result;
    } on RequestRefusedException catch (e) {
      if (e.refusedWithoutBooking) await clear();
      rethrow;
    } on SubmitAlreadySavedException {
      await clear();
      // The draft itself is spent too: kept, the next tap would send it with a
      // fresh key and book the document a second time.
      await _drafts.remove(_draftScope);
      onAlreadySaved?.call();
      rethrow;
    }
  }

  static final Random _random = Random.secure();

  /// 128 random bits as hex, prefixed so a key is recognisable in the logs.
  static String newKey() =>
      'app-${List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
