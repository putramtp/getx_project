// ============ PACKAGE IMPORTS ============
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ============ INTERNAL IMPORTS ============
import 'package:getx_project/app/data/models/product_unit_model.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/widget/master_list_view.dart';
import 'package:getx_project/app/modules/product-unit/controllers/product_unit_controller.dart';
import 'package:getx_project/app/routes/app_pages.dart';

class ProductUnitView extends GetView<ProductUnitController> {
  const ProductUnitView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MasterListView<ProductUnitModel>(
      title: "Unit",
      icon: Icons.thermostat_auto,
      routeBackName: AppPages.homePage,
      isLoading: controller.isLoading,
      isSearchFocused: controller.isSearchFocused,
      isAscending: controller.isAscending,
      cursorNext: controller.cursorNext,
      limit: controller.limit,
      items: controller.units,
      hasError: controller.hasError,
      searchController: controller.searchController,
      searchFocus: controller.searchFocus,
      onRefresh: controller.loadUnits,
      onSearchChanged: controller.onSearchChanged,
      onToggleSort: controller.toggleSort,
      onLoadMore: controller.loadMore,
      onApplyLimit: (value) {
        controller.limit.value = value;
        controller.applyFilter();
      },
      onClearFilter: controller.clearFilter,
      emptyMessage: "No unit data.",
      itemBuilder: (context, unit) {
        final size = SizeConfig.defaultSize;
        final hasDescription = unit.description.trim().isNotEmpty;
        return masterListCard(
          size: size,
          accent: getAccentColor2(unit.name),
          avatarText: masterMonogram(unit.name),
          title: unit.name,
          subtitle: hasDescription ? unit.description : 'No description',
          subtitleColor: hasDescription ? null : Colors.grey[400],
          onTap: () => _showUnitDetail(context, unit, size),
        );
      },
    );
  }

  // ── Unit detail popup ────────────────────────────────────────────
  void _showUnitDetail(BuildContext context, ProductUnitModel unit, double size) {
    final accent = getAccentColor2(unit.name);
    final hasDescription = unit.description.trim().isNotEmpty;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Unit Detail',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 3),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 2.4),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Gradient header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        vertical: size * 2.6, horizontal: size * 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.white, 0.35)!,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: size * 7,
                          height: size * 7,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            masterMonogram(unit.name),
                            style: AppTextStyle.h3(size, color: accent),
                          ),
                        ),
                        SizedBox(height: size * 1.2),
                        Text(
                          unit.name,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.h4(size, color: Colors.white),
                        ),
                        SizedBox(height: size * 0.3),
                        Text(
                          'Product Unit',
                          style: AppTextStyle.overline(size,
                              color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),

                  /// Body
                  Padding(
                    padding: EdgeInsets.all(size * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESCRIPTION',
                            style: AppTextStyle.overline(size,
                                color: Colors.grey)),
                        SizedBox(height: size * 0.8),
                        Text(
                          hasDescription
                              ? unit.description
                              : 'No description provided.',
                          style: AppTextStyle.body(
                            size,
                            color: hasDescription
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        SizedBox(height: size * 2),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              elevation: 0,
                              padding:
                                  EdgeInsets.symmetric(vertical: size * 1.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(size * 1.4),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text('Close',
                                style: AppTextStyle.bodyBold(size,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }
}
