import 'package:flutter/material.dart';
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/global/styles/app_text_style.dart';
import 'package:getx_project/app/global/variables.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';
import 'package:getx_project/app/global/widget/stock_level_tile.dart';

class ProductTile extends StatelessWidget {
  final ProductSummaryModel product;
  final double size;
  final VoidCallback onViewDetail;
  final VoidCallback onViewTransaction;

  const ProductTile({
    super.key,
    required this.product,
    required this.size,
    required this.onViewDetail,
    required this.onViewTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(size * 1.5),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          stockLevelTile(size, product.qtyRemaining),
          const SizedBox(width: 14),

          /// CONTENT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// TITLE
                Text(
                  product.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.h5(size,
                    color: navyDark,
                    weight: FontWeight.w600,
                  ),
                ),

                /// CODE + DETAIL BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          product.itemCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.custom(size,
                            scale: 1.15,
                            weight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: onViewDetail,
                      child: Text(
                        "View details",
                        style: AppTextStyle.custom(size, scale: 1.1),
                      ),
                    ),
                  ],
                ),

                Divider(height: size),

                /// STOCK INFO + TRANSACTION BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Remaining + low-stock status live in the leading tile.
                          textWithIcon(size, "${product.qtyIn}", Icons.arrow_drop_down, stockInColor),
                          textWithIcon(size, "${product.qtyOut}", Icons.arrow_drop_up, stockOutColor),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onViewTransaction,
                      child: Text(
                        "View Transactions",
                        style: AppTextStyle.custom(size, scale: 1.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
