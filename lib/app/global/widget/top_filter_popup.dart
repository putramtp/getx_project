import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/alert.dart';
import 'package:getx_project/app/global/functions.dart';
import 'package:getx_project/app/global/size_config.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/app_buttons.dart';

/// Opens [popup] sliding down from the top. Its fields edit the controller's
/// filter directly, so a popup closed without Apply or Clear (a tap outside,
/// Back) puts every value back as it was: left changed, the next page of the
/// list would load with a filter the rows on screen weren't loaded with — a
/// page of another query appended to them, or a 422 for an end date before the
/// start date the Apply check never saw. [extra]: the screen's own filter
/// values edited in [TopDateFilterPopup.children].
Future<void> showTopFilterPopup(BuildContext context, TopDateFilterPopup popup, {List<Rx> extra = const []}) async {
  final c = popup.controller;
  final start = c.startDate.value, end = c.endDate.value, limit = c.limit.value;
  final priceOn = c.enablePriceRange.value, minPrice = c.minPrice.value, maxPrice = c.maxPrice.value;
  final extraKept = [for (final r in extra) r.value];

  final applied = await showGeneralDialog<bool>(
    context: context,
    barrierLabel: "Filter",
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => popup,
    transitionBuilder: (context, anim1, anim2, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
      child: FadeTransition(opacity: anim1, child: child),
    ),
  );
  if (applied == true) return;

  c.startDate.value = start;
  c.endDate.value = end;
  c.limit.value = limit;
  c.enablePriceRange.value = priceOn;
  c.minPrice.value = minPrice;
  c.maxPrice.value = maxPrice;
  for (var i = 0; i < extra.length; i++) {
    extra[i].value = extraKept[i];
  }
}

class TopDateFilterPopup<T extends TopFilterController> extends StatelessWidget {
  const TopDateFilterPopup({super.key, required this.controller,  this.showPrice = false , this.showDateRange = true, this.children});

  final T controller;
  final bool showPrice;
  final bool showDateRange;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: SafeArea( 
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dragHandle(),
                  const SizedBox(height: 16),
                  Text(
                    "Filter Options",
                    style: AppTextStyle.custom(SizeConfig.defaultSize,
                      px: 18,
                      weight: FontWeight.bold,
                    ),
                  ),
                  if (showDateRange) ...[
                  const SizedBox(height: 16),
                  Obx(() =>
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            context,
                            label: "Start Date",
                            value: controller.startDate.value != null
                                ? controller.formatDate(
                                    controller.startDate.value!,
                                  )
                                : "Start date",
                            onTap: () => controller.pickStartDate(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _dateField(
                            context,
                            label: "End Date",
                            value: controller.endDate.value != null
                                ? controller.formatDate(
                                    controller.endDate.value!,
                                  )
                                : "End date",
                            onTap: () => controller.pickEndDate(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                  const SizedBox(height: 20),
                  // LIMIT FILTER
                  Text(
                    "Limit",
                    style: AppTextStyle.custom(SizeConfig.defaultSize, px: 14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: controller.limit.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    // The list endpoints accept a limit of 1–200 (CursorRequest).
                    items: const [20, 50, 100, 200]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text("$e items"),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) controller.limit.value = value;
                    },
                  ),

                  // PRICE RANGE FILTER
                  if (showPrice) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Price Range",
                          style: AppTextStyle.custom(SizeConfig.defaultSize, px: 14, weight: FontWeight.w600),
                        ),
                        Obx(() => Switch(
                          activeThumbColor: navyMid,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white,
                          value: controller.enablePriceRange.value,
                          onChanged: (value) {
                            controller.enablePriceRange.value = value;
                          },
                        )),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      if (!controller.enablePriceRange.value) {
                        return const SizedBox();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Rp ${formatPrice(controller.minPrice.value)}"
                            " - Rp ${formatPrice(controller.maxPrice.value)}",
                            style: AppTextStyle.plain(color: Colors.grey.shade600),
                          ),
                          RangeSlider(
                            activeColor: navyMid,
                            min: 0,
                            max: 100000000,
                            divisions: 1000,
                            values: RangeValues(
                              controller.minPrice.value,
                              controller.maxPrice.value,
                            ),
                            onChanged: (values) {
                              controller.minPrice.value = values.start;
                              controller.maxPrice.value = values.end;
                            },
                          ),
                        ],
                      );
                    }),
                  ],
                  if (children != null) ...[
                    const SizedBox(height: 12),
                    ...children!,
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: accentOutlineButton(
                          SizeConfig.defaultSize,
                          "Clear",
                          color: navyDark,
                          icon: Icons.clear,
                          onPressed: () {
                            controller.clearFilter();
                            closeRoute(true); // applied: keep (see showTopFilterPopup)
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: navyButton(
                          SizeConfig.defaultSize,
                          "Apply",
                          icon: Icons.check,
                          onPressed: () {
                            final start = controller.startDate.value;
                            final end = controller.endDate.value;
                            // The backend refuses it (end_date after_or_equal start_date).
                            if (showDateRange && start != null && end != null && end.isBefore(start)) {
                              warningAlertBottom('The end date is before the start date.', title: 'Date Filter');
                              return;
                            }
                            controller.applyFilter();
                            closeRoute(true); // applied: keep (see showTopFilterPopup)
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              )
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

  Widget _dateField(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyle.custom(SizeConfig.defaultSize, px: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    AppTextStyle.custom(SizeConfig.defaultSize, px: 14, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

abstract class TopFilterController {
  // Date
  Rx<DateTime?> get startDate;
  Rx<DateTime?> get endDate;

  // Pagination / limit
  RxInt get limit;

  // Price range
  RxBool get enablePriceRange;
  RxDouble get minPrice;
  RxDouble get maxPrice;

  String formatDate(DateTime date);

  Future<void> pickStartDate(BuildContext context);
  Future<void> pickEndDate(BuildContext context);

  void applyFilter();
  void clearFilter();
}

