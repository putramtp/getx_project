import 'package:get/get.dart';

/// Keeps a cursor-paginated list consistent when its loads overlap.
///
/// - A reload asked for while one is still running (a new search during a slow
///   answer, a sort or filter tapped meanwhile) is not dropped: it runs once
///   the current one ends, with the query as it is then — so the list always
///   ends on the latest query. `ApiExecutor.run` alone would return null for it.
/// - A next page that answers after a reload started belongs to the old query:
///   [isCurrentPage] tells `loadMore` to throw it away instead of appending it
///   and overwriting the new cursor.
///
/// Usage: `Future<void> loadX() => guardReload(isLoading, _loadX);`, and in
/// `loadMore` take `final generation = listGeneration;` before the call and
/// return when `!isCurrentPage(generation)` after it.
mixin ListReloadGuard on GetxController {
  int _generation = 0;
  bool _reloadQueued = false;

  Future<void> guardReload(RxBool isLoading, Future<void> Function() load) async {
    if (isLoading.value) {
      _reloadQueued = true;
      return;
    }
    _generation++;
    await load();
    if (_reloadQueued && !isClosed) {
      _reloadQueued = false;
      await guardReload(isLoading, load);
    }
  }

  DateTime? _moreFailedAt;

  /// False for a few seconds after a next page failed. Scrolling near the end
  /// fires `loadMore` on every scroll notification: offline, each try queued
  /// another "No internet connection" snackbar.
  bool get mayLoadMore =>
      _moreFailedAt == null || DateTime.now().difference(_moreFailedAt!) > const Duration(seconds: 5);

  /// Call when a next page failed (see [mayLoadMore]).
  void noteLoadMoreFailed() => _moreFailedAt = DateTime.now();

  /// Snapshot of the list's reload count, taken before a next-page call.
  int get listGeneration => _generation;

  /// Whether a page fetched at [generation] still belongs to the list.
  bool isCurrentPage(int generation) => generation == _generation && !isClosed;
}
