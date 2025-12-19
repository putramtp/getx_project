import 'package:flutter/material.dart';
import 'package:getx_project/app/data/models/product_summary_model.dart';
import 'package:getx_project/app/global/widget/functions_widget.dart';

class ProductTile extends StatelessWidget {
  final ProductSummaryModel product;
  final double size;
  final VoidCallback onViewDetail;
  final VoidCallback onViewTransaction;

  const ProductTile({
    Key? key,
    required this.product,
    required this.size,
    required this.onViewDetail,
    required this.onViewTransaction,
  }) : super(key: key);

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
          CircleAvatar(
            radius: size * 2.8,
            backgroundColor: const Color.fromARGB(255, 220, 230, 221),
            child: Icon(
              Icons.stars_rounded,
              color: const Color.fromARGB(255, 77, 164, 175),
              size: size * 2.4,
            ),
          ),
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
                  style: TextStyle(
                    fontSize: size * 1.6,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 35, 132, 211),
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
                          style: TextStyle(
                            fontSize: size * 1.15,
                            fontWeight: FontWeight.w600,
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
                        style: TextStyle(fontSize: size * 1.1),
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
                          textWithIcon(
                            size,
                            "${product.qtyRemaining}",
                            Icons.archive,
                            Colors.blue,
                          ),
                          textWithIcon(
                            size,
                            "${product.qtyIn}",
                            Icons.arrow_drop_down,
                            Colors.green,
                          ),
                          textWithIcon(
                            size,
                            "${product.qtyOut}",
                            Icons.arrow_drop_up,
                            Colors.red,
                          ),
                          if (product.lowStock)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: size * 0.6,
                                vertical: size * 0.4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Low Stock",
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: size * 1.1,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onViewTransaction,
                      child: Text(
                        "View Transactions",
                        style: TextStyle(fontSize: size * 1.1),
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
