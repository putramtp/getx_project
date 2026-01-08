import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_project/app/global/functions.dart';

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
                  color: Colors.black.withOpacity(0.1),
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
                  const Text(
                    "Filter Options",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                  const Text(
                    "Limit",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: controller.limit.value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [20, 50, 100,200,1000]
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
                        const Text(
                          "Price Range",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Obx(() => Switch(
                          activeColor: Colors.blue[300],
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
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          RangeSlider(
                            activeColor: Colors.blue[300],
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
                        child: OutlinedButton.icon(
                          onPressed: () {
                            controller.clearFilter();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text("Clear"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            controller.applyFilter();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            "Apply",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  /// 👇 injected children
                
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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

