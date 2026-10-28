// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/global/accent.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/app_header.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/global/widget/search_bar.dart';
import 'package:getx_project/app/global/widget/skeleton_widgets.dart';

/// Shared scaffold for the "master data" list screens (Category, Brand, Unit).
///
/// These screens are structurally identical — an app bar, a debounced search
/// bar with sort + limit filter, a cursor-paginated list with a skeleton
/// loading state, an empty state, and a pagination footer. Only the row content
/// and the data type differ, so callers pass the reactive state, the callbacks,
/// and an [itemBuilder]. Use [masterListCard] to render rows consistently.
class MasterListView<T> extends StatelessWidget {
  final String title;
  final IconData icon;

  // Reactive state (owned by the caller's controller)
  final RxBool isLoading;
  final RxBool isSearchFocused;
  final RxBool isAscending;
  final RxnString cursorNext;
  final RxInt limit;
  final RxList<T> items;

  /// Optional load-failure flag. When true and [items] is empty, an error+retry
  /// state is shown instead of the empty state.
  final RxBool? hasError;

  // Text input
  final TextEditingController searchController;
  final FocusNode searchFocus;

  // Callbacks
  final Future<void> Function() onRefresh;
  final void Function(String value) onSearchChanged;
  final VoidCallback onToggleSort;
  final VoidCallback onLoadMore;
  final void Function(int limit) onApplyLimit;
  final VoidCallback onClearFilter;

  // Row rendering
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;

  const MasterListView({
    super.key,
    required this.title,
    required this.icon,
    required this.isLoading,
    required this.isSearchFocused,
    required this.isAscending,
    required this.cursorNext,
    required this.limit,
    required this.items,
    this.hasError,
    required this.searchController,
    required this.searchFocus,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onToggleSort,
    required this.onLoadMore,
    required this.onApplyLimit,
    required this.onClearFilter,
    required this.itemBuilder,
    this.emptyMessage = 'No data.',
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final size = SizeConfig.defaultSize;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: appHeader(title, accent: AppAccent.slate, icon: icon, subtitle: 'Master data'),
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Obx(() => SearchBarWidget(
                      isFocused: isSearchFocused.value,
                      isAscending: isAscending.value,
                      searchController: searchController,
                      focusNode: searchFocus,
                      onSearchChanged: onSearchChanged,
                      onToggleSort: onToggleSort,
                      onOpenFilter: () => _showLimitDialog(context, size),
                    )),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (isLoading.value) {
                      return skeletonGenericList(size);
                    }
                    if ((hasError?.value ?? false) && items.isEmpty) {
                      return errorRetry(size, onRetry: onRefresh, accent: navyDark);
                    }
                    if (items.isEmpty) {
                      return textNoData(size, message: emptyMessage);
                    }
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 250) {
                          onLoadMore();
                        }
                        return false;
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: items.length + 1,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: size * 1.2),
                        itemBuilder: (context, index) {
                          if (index < items.length) {
                            return itemBuilder(context, items[index]);
                          }
                          return _paginationFooter(size);
                        },
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationFooter(double size) {
    if (cursorNext.value != null && limit.value >= 8) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }
    if (cursorNext.value == null && items.isNotEmpty) {
      return NoMoreDataFooter(size: size);
    }
    return const SizedBox.shrink();
  }

  void _showLimitDialog(BuildContext context, double size) {
    final TextEditingController tController =
        TextEditingController(text: limit.value.toString());

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Limit Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) {
        return Center(
          child: Material(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set Limit', style: AppTextStyle.h4(size)),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('masterLimitField'),
                      controller: tController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Limit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            onClearFilter();
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: navyDark),
                          onPressed: () {
                            final value = int.tryParse(tController.text);
                            if (value == null || value <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid number'),
                                ),
                              );
                              return;
                            }
                            onApplyLimit(value);
                            Navigator.pop(context);
                          },
                          child: Text('Apply',
                              style: AppTextStyle.plain(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    ).whenComplete(tController.dispose);
  }
}

/// Which master list a [masterListCard] belongs to (picks its kind badge).
enum MasterKind {
  brand(Icons.sell_rounded),
  category(Icons.category_rounded),
  unit(Icons.straighten_rounded);

  const MasterKind(this.icon);
  final IconData icon;
}

/// A master-data row (Category / Brand / Unit): outlined card, a tinted code
/// tile with a small kind badge, title + subtitle and a navy chevron. The tile
/// color comes from [accentFor] on the title, so it is stable per item.
Widget masterListCard({
  required double size,
  required MasterKind kind,
  required String avatarText,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  bool subtitleMissing = false,
}) {
  final accent = accentFor(title);
  final radius = BorderRadius.circular(14);
  return InkWell(
    borderRadius: radius,
    onTap: onTap,
    child: Ink(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: cardOutline),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 1.3),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    key: const Key('masterListTile'),
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: accent.tint(.14), borderRadius: BorderRadius.circular(12)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        avatarText,
                        maxLines: 1,
                        style: AppTextStyle.custom(size, scale: 1.4, weight: FontWeight.w800, color: accent.text),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: cardOutline),
                      ),
                      child: Icon(kind.icon, size: 11, color: accent.text),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: size * 1.3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyle.h5(size, weight: FontWeight.w700, color: navyDark),
                  ),
                  SizedBox(height: size * 0.3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleMissing
                        ? AppTextStyle.small(size, color: Colors.grey.shade400).copyWith(fontStyle: FontStyle.italic)
                        : AppTextStyle.small(size, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            SizedBox(width: size * 0.8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: navyMid.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.chevron_right_rounded, size: 20, color: navyMid),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Builds a 1–2 letter monogram from a name (fallback avatar text).
String masterMonogram(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return trimmed.length >= 2
      ? trimmed.substring(0, 2).toUpperCase()
      : trimmed.toUpperCase();
}
